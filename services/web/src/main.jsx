import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.jsx";
import "./style.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
#import React, {useEffect, useState} from "react";
#import {createRoot} from "react-dom/client";

const API = import.meta.env.VITE_API_URL || "http://localhost:8000";

function App() {
  const [products, setProducts] = useState([]);
  const [cart, setCart] = useState([]);
  const [q, setQ] = useState("");
  const [order, setOrder] = useState(null);
  const [status, setStatus] = useState("");

  async function load() {
    const r = await fetch(`${API}/products${q ? `?q=${encodeURIComponent(q)}` : ""}`);
    setProducts(await r.json());
  }
  useEffect(() => { load(); }, [q]);

  function add(p) {
    setCart(c => {
      const old = c.find(x => x.id === p.id);
      if (old) return c.map(x => x.id === p.id ? {...x, quantity:x.quantity+1} : x);
      return [...c, {...p, quantity:1}];
    });
  }

  async function checkout() {
    if (!cart.length) return;
    const r = await fetch(`${API}/orders`, {
      method:"POST", headers:{"Content-Type":"application/json"},
      body:JSON.stringify({
        customer_name:"Demo Customer",
        address:"Hyderabad, Telangana",
        items:cart.map(x => ({product_id:x.id, quantity:x.quantity}))
      })
    });
    const data = await r.json();
    if (!r.ok) return alert(data.detail || "Checkout failed");
    setOrder(data); setStatus(data.status); setCart([]);
    const ws = new WebSocket(`${location.protocol === "https:" ? "wss" : "ws"}://${location.host}/ws/orders/${data.id}`);
    ws.onmessage = e => setStatus(JSON.parse(e.data).status);
  }

  const total = cart.reduce((s,x)=>s+Number(x.price)*x.quantity,0);

  return <div className="app">
    <header><h1>QuickCart</h1><span>10-minute grocery demo</span></header>
    <main>
      <section>
        <input placeholder="Search groceries..." value={q} onChange={e=>setQ(e.target.value)} />
        <div className="grid">{products.map(p =>
          <article key={p.id}>
            <img src={p.image_url} />
            <h3>{p.name}</h3><p>{p.category}</p>
            <b>₹{p.price}</b>
            <button disabled={!p.stock} onClick={()=>add(p)}>{p.stock ? "Add" : "Out of stock"}</button>
          </article>
        )}</div>
      </section>
      <aside>
        <h2>Cart ({cart.length})</h2>
        {cart.map(x=><div className="row" key={x.id}><span>{x.name} × {x.quantity}</span><b>₹{Number(x.price)*x.quantity}</b></div>)}
        <hr/><h3>Total: ₹{total.toFixed(2)}</h3>
        <button className="checkout" onClick={checkout}>Place order</button>
        {order && <div className="tracking"><h3>Order #{order.id}</h3><strong>{status}</strong><p>Live status updates via WebSocket</p></div>}
      </aside>
    </main>
  </div>
}
createRoot(document.getElementById("root")).render(<App />);
