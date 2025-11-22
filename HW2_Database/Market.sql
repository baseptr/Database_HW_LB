--Task 1
DROP TABLE IF EXISTS Order_Items CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS Products CASCADE;


CREATE TABLE Orders
(
    o_id       SERIAL PRIMARY KEY,
    order_date DATE NOT NULL,
    CONSTRAINT orders_pkey PRIMARY KEY (o_id)
);


CREATE TABLE Products
(
    p_name TEXT PRIMARY KEY,
    price  MONEY NOT NULL,
    CONSTRAINT products_pkey PRIMARY KEY (p_name)
);


CREATE TABLE Order_Items
(
    order_id     INTEGER       NOT NULL,
    product_name TEXT          NOT NULL,
    amount       NUMERIC(7, 2) NOT NULL DEFAULT 1 CHECK (amount > 0),
    PRIMARY KEY (order_id, product_name),
    FOREIGN KEY (order_id) REFERENCES Orders (o_id) ON DELETE CASCADE,
    FOREIGN KEY (product_name) REFERENCES Products (p_name) ON DELETE CASCADE,
    CONSTRAINT order_items_pkey PRIMARY KEY (order_id, product_name),
    CONSTRAINT order_items_amount_check CHECK (amount > 0),
    CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES Orders(o_id) ON DELETE CASCADE,
    CONSTRAINT order_items_product_name_fkey FOREIGN KEY (product_name) REFERENCES Products(p_name) ON DELETE CASCADE
);

--Task 2 insert data
INSERT INTO Orders (order_date)
VALUES ('2024-01-15'),
       ('2024-01-20');


INSERT INTO Products (p_name, price)
VALUES ('p1', 100.00),
       ('p2', 250.50);


INSERT INTO Order_Items (order_id, product_name)
VALUES (1, 'p1'),
       (1, 'p2');


INSERT INTO Order_Items (order_id, product_name, amount)
VALUES (2, 'p1', 3),
       (2, 'p2', 5);

--Task 3 migration


ALTER TABLE Products
    ADD COLUMN p_id SERIAL;

ALTER TABLE Order_Items
    ADD COLUMN product_id INTEGER;

UPDATE Order_Items oi
SET product_id = p.p_id
FROM Products p
WHERE oi.product_name = p.p_name;


ALTER TABLE Order_Items
    ALTER COLUMN product_id SET NOT NULL;

ALTER TABLE Products
    ALTER COLUMN p_id SET NOT NULL;


ALTER TABLE Order_Items
    DROP CONSTRAINT order_items_pkey;


ALTER TABLE Order_Items
    DROP CONSTRAINT order_items_product_name_fkey;


ALTER TABLE Products
    DROP CONSTRAINT products_pkey;


ALTER TABLE Products
    ADD PRIMARY KEY (p_id);


ALTER TABLE Products
    ADD CONSTRAINT products_p_name_unique UNIQUE (p_name);


ALTER TABLE Order_Items
    ADD PRIMARY KEY (order_id, product_id);


ALTER TABLE Order_Items
    ADD CONSTRAINT order_items_product_id_fkey
        FOREIGN KEY (product_id) REFERENCES Products (p_id) ON DELETE CASCADE;


ALTER TABLE Order_Items
    DROP COLUMN product_name;


ALTER TABLE Order_Items
    ADD COLUMN price MONEY;


UPDATE Order_Items oi
SET price = p.price
FROM Products p
WHERE oi.product_id = p.p_id;


ALTER TABLE Order_Items
    ALTER COLUMN price SET NOT NULL;


ALTER TABLE Order_Items
    ADD COLUMN total MONEY;


UPDATE Order_Items
SET total = amount * price;


ALTER TABLE Order_Items
    ALTER COLUMN total SET NOT NULL;


ALTER TABLE Order_Items
    ADD CONSTRAINT order_items_total_check
        CHECK (total = amount * price);


--Task 4 data update
UPDATE Products
SET p_name = 'product1'
WHERE p_name = 'p1';


DELETE
FROM Order_Items
WHERE order_id = 1
  AND product_id = (SELECT p_id FROM Products WHERE p_name = 'p2');


DELETE
FROM Orders
WHERE o_id = 2;


UPDATE Products
SET price = 5.00
WHERE p_name = 'product1';


UPDATE Order_Items
SET price = 5.00,
    total = amount * 5.00
WHERE product_id = (SELECT p_id FROM Products WHERE p_name = 'product1');


INSERT INTO Orders (order_date)
VALUES (CURRENT_DATE);


INSERT INTO Order_Items (order_id, product_id, amount, price, total)
SELECT (SELECT MAX(o_id) FROM Orders),
       p.p_id,
       3,
       p.price,
       3 * p.price
FROM Products p
WHERE p.p_name = 'product1';

