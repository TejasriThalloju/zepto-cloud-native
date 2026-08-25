from pydantic import BaseModel, Field

class ProductOut(BaseModel):
    id: int
    name: str
    category: str
    price: float
    image_url: str
    stock: int
    model_config = {"from_attributes": True}

class CartItem(BaseModel):
    product_id: int
    quantity: int = Field(gt=0)

class OrderCreate(BaseModel):
    customer_name: str = Field(min_length=2)
    address: str = Field(min_length=5)
    items: list[CartItem]

class OrderOut(BaseModel):
    id: int
    customer_name: str
    address: str
    total: float
    status: str
    model_config = {"from_attributes": True}
