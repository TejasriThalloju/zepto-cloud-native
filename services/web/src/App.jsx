import { useState } from "react";
import "./style.css";

const products = [
{ id: 1, name: "Banana", price: 40, emoji: "🍌" },
{ id: 2, name: "Milk", price: 30, emoji: "🥛" },
{ id: 3, name: "Bread", price: 45, emoji: "🍞" },
{ id: 4, name: "Tomato", price: 35, emoji: "🍅" },
{ id: 5, name: "Potato", price: 30, emoji: "🥔" },
{ id: 6, name: "Eggs", price: 80, emoji: "🥚" }
];

function App() {
const [cart, setCart] = useState([]);
const [search, setSearch] = useState("");

const addToCart = (product) => {
setCart([...cart, product]);
};

const filteredProducts = products.filter((product) =>
product.name.toLowerCase().includes(search.toLowerCase())
);

const total = cart.reduce(
(sum, item) => sum + item.price,
0
);

return (
<> <header className="header"> <h1>QuickCart</h1> <p>⚡ 10-minute grocery delivery</p> </header>

```
  <main className="container">
    <section className="products-section">
      <input
        className="search"
        type="text"
        placeholder="Search groceries..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />

      <h2>Popular Products</h2>

      <div className="product-grid">
        {filteredProducts.map((product) => (
          <div className="product-card" key={product.id}>
            <div className="product-image">
              {product.emoji}
            </div>

            <h3>{product.name}</h3>
            <p>₹{product.price}</p>

            <button onClick={() => addToCart(product)}>
              ADD
            </button>
          </div>
        ))}
      </div>
    </section>

    <aside className="cart">
      <h2>🛒 Cart ({cart.length})</h2>

      <hr />

      {cart.length === 0 ? (
        <p>Your cart is empty</p>
      ) : (
        cart.map((item, index) => (
          <div className="cart-item" key={index}>
            <span>{item.name}</span>
            <span>₹{item.price}</span>
          </div>
        ))
      )}

      <hr />

      <h3>Total: ₹{total}</h3>

      <button className="order-button">
        Place Order
      </button>
    </aside>
  </main>
</>
);
}

export default App;
