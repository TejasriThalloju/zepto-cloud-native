CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price NUMERIC(10,2) NOT NULL,
    stock INTEGER DEFAULT 0,
    image_url TEXT
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'PLACED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL
);

INSERT INTO products (name, category, price, stock, image_url)
VALUES
(
    'Banana',
    'Fruits',
    50.00,
    100,
    'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e'
),
(
    'Milk',
    'Dairy',
    30.00,
    50,
    'https://images.unsplash.com/photo-1563636619-e9143da7973b'
),
(
    'Bread',
    'Bakery',
    40.00,
    30,
    'https://images.unsplash.com/photo-1509440159596-0249088772ff'
),
(
    'Tomato',
    'Vegetables',
    35.00,
    80,
    'https://images.unsplash.com/photo-1546094096-0df4bcaaa337'
),
(
    'Potato',
    'Vegetables',
    25.00,
    100,
    'https://images.unsplash.com/photo-1518977676601-b53f82aba655'
),
(
    'Eggs',
    'Dairy',
    90.00,
    40,
    'https://images.unsplash.com/photo-1506976785307-8732e854ad03'
)
ON CONFLICT DO NOTHING;