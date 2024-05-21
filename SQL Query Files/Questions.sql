-- 1. List all customers along with their orders, including order status and order dates.

SELECT 
	c.*,
	o.order_id, 
	o.order_status, 
	o.order_date,
	o.required_date,
	o.shipped_date
FROM 
	customers c 
JOIN 
	orders o ON c.customer_id = o.customer_id; 

-- 2. Find the total number of orders placed by each customer.

SELECT 
	c.first_name,
	c.last_name, 
	COUNT(order_id) as Total_Orders
FROM 
	orders o 
JOIN 
	customers c ON o.customer_id = c.customer_id 
GROUP BY 
	o.customer_id, c.first_name, c.last_name;

-- 3. Retrieve the total sales (quantity * list_price) for each product.

SELECT 
	p.product_name,
	o.product_id, 
	o.list_price,
	SUM(o.quantity * o.list_price) AS total_sales 
FROM 
	order_items o
JOIN 
	products p ON o.product_id = p.product_id
GROUP BY 
	o.product_id, p.product_name, o.list_price;


-- 4. List all products that are currently out of stock.

SELECT 
	p.product_name, 
	s.quantity 
FROM 
	stocks s
LEFT JOIN 
	products p ON s.product_id = p.product_id
WHERE 
	s.quantity = 0;

-- 5. Find the most popular product category based on the number of products sold.

SELECT 
	c.category_name,
	SUM(o.quantity) AS total_sales
FROM 
	order_items o 
JOIN 
	products p ON o.product_id = p.product_id
JOIN 
	categories c ON c.category_id = p.category_id
GROUP BY 
	p.category_id, c.category_name 
ORDER BY 
	total_sales DESC
LIMIT 1;


-- 6. Get a list of all completed orders along with the customer details and the total order amount.

SELECT 
	ot.order_id, 
	o.customer_id, 
	c.first_name, 
	c.last_name, 
	ROUND(SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount::numeric)),2) AS total_amounts 
FROM 
	orders o
LEFT JOIN 
	order_items ot ON o.order_id = ot.order_id 
LEFT JOIN 
	customers c ON c.customer_id = o.customer_id 
WHERE 
	o.order_status = 4 
GROUP BY 
	ot.order_id, o.customer_id, c.first_name, c.last_name;


-- 7. List all staff members along with the store they work for.

SELECT 
	sf.*, 
	st.store_name
FROM 
	staffs sf
JOIN 
	stores st ON sf.store_id = st.store_id;


-- 8. Find the average list price of products for each brand.

SELECT 
	b.brand_name, 
	ROUND(AVG(CAST(list_price AS numeric)), 2) as avg_price 
FROM 
	products p
JOIN 
	brands b ON p.brand_id = b.brand_id
GROUP BY 
	b.brand_id, b.brand_name;

-- 9. Identify the top 3 customers based on the total amount spent on their orders.

SELECT 
	ot.order_id, 
	o.customer_id, 
	c.first_name, 
	c.last_name, 
	ROUND(SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount::numeric)),2) AS total_amounts 
FROM 
	orders o
LEFT JOIN 
	order_items ot ON o.order_id = ot.order_id 
LEFT JOIN 
	customers c ON c.customer_id = o.customer_id 
WHERE 
	o.order_status = 4 
GROUP BY 
	ot.order_id, o.customer_id, c.first_name, c.last_name
ORDER BY 
	total_amounts DESC
LIMIT 3;


-- 10. Get a count of orders for each order status.
SELECT 
	order_status, 
	COUNT(order_id) AS Total_orders 
FROM 
	orders 
GROUP BY 
	order_status;

-- 11. List all customers who have placed more than 2 orders.

SELECT 
	c.first_name,
	c.last_name, 
	COUNT(o.order_id) as Total_Orders
FROM 
	orders o 
JOIN 
	customers c ON o.customer_id = c.customer_id 
GROUP BY 
	o.customer_id, c.first_name, c.last_name
HAVING 
	COUNT(order_id) > 2;


-- 12. Find the total number of products sold by each store.
SELECT 
	s.store_id, 
	s.store_name, 
	SUM(ot.quantity) AS num_products 
FROM 
	products p 
JOIN 
	order_items ot ON p.product_id = ot.product_id
JOIN 
	orders o ON o.order_id = ot.order_id
JOIN 
	stores s ON o.store_id = s.store_id
GROUP BY 
	s.store_id, s.store_name;


-- 13. Identify the top 5 best-selling products.

SELECT 
	ot.product_id, 
	p.product_name, 
	SUM(ot.quantity) AS total_sales 
FROM 
	order_items ot 
JOIN 
	products p ON ot.product_id = p.product_id
GROUP BY 
	ot.product_id, p.product_name
ORDER BY 
	total_sales DESC
LIMIT 5;

-- 14. Retrieve all orders along with the total discount applied to each order.

SELECT 
	order_id, 
	ROUND(SUM(quantity::numeric * list_price::numeric * discount::numeric), 2) AS total_discount 
FROM 
	order_items 
GROUP BY 
	order_id;

-- 15. List the products that have never been sold.

SELECT 
	p.product_name, 
	p.product_id
FROM 
	products p
LEFT JOIN 
	order_items ot ON p.product_id = ot.product_id
WHERE 
	ot.product_id IS NULL;

-- 16. A function to retrieve the total sales for a given product ID.

-- DROP FUNCTION Total_sales(IN pr_id int);

CREATE OR REPLACE FUNCTION Total_sales(
	IN pr_id int
)
RETURNS TABLE(p_id INT, p_name TEXT, p_total_sales NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		ot.product_id::INT,
		p.product_name,
		SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount::numeric))
	FROM order_items ot
	JOIN products p
	ON p.product_id = ot.product_id
	WHERE ot.product_id = pr_id
	GROUP BY ot.product_id, p.product_name;
END
$$

-- Calling the function with product id

SELECT * FROM Total_sales(6);
SELECT * FROM Total_sales(97);

-- 17. A stored procedure that updates the quantity of a product in stock for a given product ID and store ID.

CREATE OR REPLACE PROCEDURE update_quantity(
	IN s_id int,
	IN p_id int,
	IN s_qt int
)
AS $$
DECLARE
BEGIN
	UPDATE stocks
	SET quantity = s_qt
	WHERE product_id = p_id AND store_id = s_id;
	COMMIT;
	
	RAISE NOTICE 'Product Quantity Updated!';
END;
$$
LANGUAGE plpgsql;

-- Calling the procedure

CALL update_quantity(1, 3, 10);

-- Checking updated row

SELECT * FROM stocks WHERE store_id = 1 and product_id = 3;

-- 18. A stored procedure to get all orders for a given customer ID, including order details and total amount.

CREATE OR REPLACE FUNCTION customer_orders(
	IN c_id int
)
RETURNS TABLE(
	c_order_id int, 
	c_order_status int, 
	c_order_date date, 
	c_required_date date, 
	c_shipped_date date, 
	total_amount numeric)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		o.order_id::int, o.order_status::int, o.order_date::date, o.required_date::date, o.shipped_date::date,
		SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount::numeric)) AS total_amount
	FROM 
		order_items ot
	JOIN 
		orders o ON o.order_id = ot.order_id
	WHERE 
		o.customer_id = c_id
	GROUP BY 
		o.order_id, o.order_status, o.order_date, o.required_date, o.shipped_date;
END
$$

-- Calling the function with customer id

SELECT * FROM customer_orders(11);
SELECT * FROM customer_orders(31);

-- 19. Retrieve the total sales for each product, 
-- along with the cumulative total sales up to the current row, 
-- ordered by total sales descending.

SELECT
	ot.product_id, p.product_name,
	SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount::numeric)) AS total_sales,
	SUM(SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount::numeric))) OVER (
		ORDER BY SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount::numeric)) DESC
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	) AS cumsum
FROM 
	order_items ot
JOIN 
	products p ON p.product_id = ot.product_id
GROUP BY 
	ot.product_id, p.product_name
ORDER BY 
	total_sales DESC;


-- 20. Calculate the running total of orders placed by each customer, ordered by order date.

SELECT 
	c.first_name, 
	c.last_name,
	o.order_id,
	o.customer_id,
	o.order_date::DATE,
	COUNT(o.order_id) OVER (
		PARTITION BY o.customer_id 
		ORDER BY o.order_date DESC
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS total_orders
FROM 
	orders o
JOIN 
	customers c ON o.customer_id = c.customer_id
GROUP BY 
	o.customer_id, o.order_date, o.order_id, c.first_name, c.last_name;

-- 21. Calculate the Rolling 7-Day Sales Total for Each Product

SELECT 
	ot.product_id, p.product_name, o.order_date,
	ROUND(SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount::numeric)),3) AS total_sales,
	ROUND(SUM(SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount::numeric)))
	OVER (
		PARTITION BY ot.product_id
		ORDER BY o.order_date
		ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
	), 3) AS seven_days_sales
FROM 
	orders o
JOIN 
	order_items ot ON o.order_id = ot.order_id
JOIN 
	products p ON p.product_id = ot.product_id
GROUP BY 
	ot.product_id, o.order_id, o.order_date, p.product_name
ORDER BY 
	ot.product_id, o.order_date;

-- 22. Calculate the Year-to-Date Sales for Each Product

SELECT 
	p.product_id,
	p.product_name,
	o.order_date,
	ROUND(SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount::numeric)),3) AS daily_sales,
	ROUND(SUM(SUM(ot.quantity::numeric * ot.list_price::numeric * (1 - ot.discount)::numeric)) OVER (
        PARTITION BY p.product_id 
        ORDER BY o.order_date 
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS ytd_sales
FROM 
	products p
JOIN 
	order_items ot ON p.product_id = ot.product_id
JOIN 
	orders o ON ot.order_id = o.order_id
GROUP BY 
	p.product_id, p.product_name, o.order_date
ORDER BY 
	p.product_id, o.order_date;

