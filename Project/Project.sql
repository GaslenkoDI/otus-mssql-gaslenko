use Final
CREATE TABLE categories 
(
    category_id   int not null identity(1, 1) PRIMARY KEY, 
    category_name VARCHAR(100) NOT NULL
);
GO


insert into Categories values	
('Компьютерная техника') ,
('Бытовая техника') ,
('Строительная техника')


CREATE TABLE manufacturer(
	manufacturer_id	    int not null identity(1, 1)  primary key,
	manufacturer_name	varchar(100) not null
)
GO

insert into manufacturer values	
('Nvidia'), 
('Makita'), 
('Haier')



CREATE TABLE products
(
    product_id int not null identity(1, 1) PRIMARY KEY,
    product_name VARCHAR(255)  NOT NULL,
    manufacturer_id int not null,    
    category_id int not null,
    FOREIGN KEY (category_id) REFERENCES categories (category_id),
    FOREIGN KEY (manufacturer_id) REFERENCES manufacturer (manufacturer_id)
);
GO

insert into products values	
('Кухонный комбайн Haier',3,2), 
('Дрель Makita',2,3), 
('Видеокарта Nvidia',1,1)

 

CREATE TABLE stores
(
    store_id int not null identity(1, 1) PRIMARY KEY,
    store_name VARCHAR(255) NOT NULL
);
GO

insert into stores values	
('Первый'), 
('Второй'), 
('Третий')


CREATE TABLE customers
(
    customer_id int not null identity(1, 1) PRIMARY KEY,
    customer_fname VARCHAR(100) NOT NULL,
    customer_lname VARCHAR(100) NOT NULL,
	TelephoneNumber VARCHAR(100) NOT NULL,
	PasmortNumber VARCHAR(100) NOT NULL,
);
GO

insert into customers values	
('Михаил','Иванов','89500008978','75158520088'), 
('Сергей','Петров','89500008967','75158520088'), 
('Иван','Павлов','89500008912','75158520088')

CREATE TABLE purchases
(
    purchase_id int not null identity(1, 1) PRIMARY KEY,
    customer_id int not null ,
    store_id int not null,
	product_id int not null,
    purchase_date DATETIME NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    FOREIGN KEY (store_id) REFERENCES stores (store_id),
	FOREIGN KEY (product_id) REFERENCES products (product_id)
);
GO
insert into purchases values	
(3,2,1,'2022-10-10'), 
(2,3,2,'2022-10-11'), 
(1,1,3,'2022-10-12')



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
