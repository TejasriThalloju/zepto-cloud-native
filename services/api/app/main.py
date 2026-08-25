import asyncio
import json
from fastapi import FastAPI, Depends, HTTPException, WebSocket, WebSocketDisconnect, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select, or_
from sqlalchemy.orm import Session
from redis.asyncio import Redis
from .config import settings
from .db import Base, engine, get_db
from .models import Product, Order, OrderItem
from .schemas import ProductOut, OrderCreate, OrderOut

app = FastAPI(title=settings.app_name, version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[x.strip() for x in settings.cors_origins.split(",")],
    allow_credentials=True, allow_methods=["*"], allow_headers=["*"]
)

redis = Redis.from_url(settings.redis_url, decode_responses=True)
ws_clients: dict[int, set[WebSocket]] = {}

SEED = [
    ("Banana", "Fruits", 40, 100, "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e"),
    ("Milk 1L", "Dairy", 65, 100, "https://images.unsplash.com/photo-1563636619-e9143da7973b"),
    ("Bread", "Bakery", 45, 80, "https://images.unsplash.com/photo-1509440159596-0249088772ff"),
    ("Tomato 1kg", "Vegetables", 55, 120, "https://images.unsplash.com/photo-1546094096-0df4bcaaa337"),
    ("Potato 1kg", "Vegetables", 40, 120, "https://images.unsplash.com/photo-1518977676601-b53f82aba655"),
    ("Eggs 12pc", "Dairy", 90, 60, "https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f"),
]

@app.on_event("startup")
def startup():
    Base.metadata.create_all(engine)
    db = next(get_db())
    try:
        if db.query(Product).count() == 0:
            for name, category, price, stock, image in SEED:
                db.add(Product(name=name, category=category, price=price, stock=stock, image_url=image))
            db.commit()
    finally:
        db.close()

@app.get("/api/health")
@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/api/ready")
@app.get("/ready")
def ready(db: Session = Depends(get_db)):
    db.execute(select(Product).limit(1))
    return {"status": "ready"}

@app.get("/api/products", response_model=list[ProductOut])
@app.get("/products", response_model=list[ProductOut])
def products(q: str | None = Query(default=None), db: Session = Depends(get_db)):
    stmt = select(Product)
    if q:
        pattern = f"%{q}%"
        stmt = stmt.where(or_(Product.name.ilike(pattern), Product.category.ilike(pattern)))
    return db.execute(stmt.order_by(Product.id)).scalars().all()

@app.post("/api/orders", response_model=OrderOut)
@app.post("/orders", response_model=OrderOut)
async def create_order(payload: OrderCreate, db: Session = Depends(get_db)):
    if not payload.items:
        raise HTTPException(400, "Cart is empty")

    products = {}
    total = 0.0
    for item in payload.items:
        p = db.get(Product, item.product_id)
        if not p or p.stock < item.quantity:
            raise HTTPException(409, f"Product {item.product_id} unavailable")
        products[p.id] = p
        total += float(p.price) * item.quantity

    order = Order(customer_name=payload.customer_name, address=payload.address, total=total, status="PLACED")
    db.add(order)
    db.flush()

    for item in payload.items:
        p = products[item.product_id]
        p.stock -= item.quantity
        db.add(OrderItem(order_id=order.id, product_id=p.id, quantity=item.quantity, unit_price=p.price))

    db.commit()
    db.refresh(order)

    await redis.setex(f"order:{order.id}", 3600, json.dumps({"status": "PLACED"}))
    asyncio.create_task(simulate_order(order.id))
    return order

@app.get("/api/orders/{order_id}", response_model=OrderOut)
@app.get("/orders/{order_id}", response_model=OrderOut)
def get_order(order_id: int, db: Session = Depends(get_db)):
    order = db.get(Order, order_id)
    if not order:
        raise HTTPException(404, "Order not found")
    return order

async def broadcast(order_id: int, status: str):
    for ws in list(ws_clients.get(order_id, set())):
        try:
            await ws.send_json({"order_id": order_id, "status": status})
        except Exception:
            ws_clients[order_id].discard(ws)

async def simulate_order(order_id: int):
    # Demo-only simulation. Replace with real fulfillment/delivery events in production.
    for status in ["CONFIRMED", "PACKING", "OUT_FOR_DELIVERY", "DELIVERED"]:
        await asyncio.sleep(5)
        db = next(get_db())
        try:
            order = db.get(Order, order_id)
            if not order:
                return
            order.status = status
            db.commit()
        finally:
            db.close()
        await redis.setex(f"order:{order_id}", 3600, json.dumps({"status": status}))
        await broadcast(order_id, status)

@app.websocket("/ws/orders/{order_id}")
async def order_socket(websocket: WebSocket, order_id: int):
    await websocket.accept()
    ws_clients.setdefault(order_id, set()).add(websocket)
    try:
        current = await redis.get(f"order:{order_id}")
        if current:
            await websocket.send_text(current)
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        ws_clients.get(order_id, set()).discard(websocket)
