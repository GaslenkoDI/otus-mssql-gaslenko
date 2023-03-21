-- Индексы
CREATE INDEX idx_Customers
ON Customers (customer_fname)
GO 

CREATE INDEX idx_Products
ON Products (product_name)
GO 

CREATE INDEX idx_Stores
ON Stores (store_name)
WHERE store_name IS NOT NULL
GO  