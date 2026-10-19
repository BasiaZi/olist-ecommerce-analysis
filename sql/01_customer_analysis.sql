-- DATA EXPLORATION
USE olist;

-- ORDERS

SELECT COUNT(*) AS total_orders
FROM orders;

SELECT COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

-- Number of orders per customer
SELECT c.customer_unique_id, COUNT(o.order_id) AS number_of_orders
FROM orders o JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
ORDER BY COUNT(o.order_id) DESC;

-- Percentage of customers with more than one order
WITH returning_customers AS(
			SELECT c.customer_unique_id, COUNT(o.order_id) AS number_of_orders
			FROM orders o JOIN customers c ON o.customer_id = c.customer_id
			GROUP BY c.customer_unique_id
			HAVING COUNT(o.order_id)>1
            )
SELECT ROUND(COUNT(customer_unique_id)*100/(SELECT COUNT(DISTINCT customer_unique_id) FROM customers),2) AS repeat_customer_percentage
FROM returning_customers;

-- Percentage of orders placed by returning customers
WITH returning_customers AS(
			SELECT c.customer_unique_id, COUNT(o.order_id) AS number_of_orders
			FROM orders o JOIN customers c ON o.customer_id = c.customer_id
			GROUP BY c.customer_unique_id
			HAVING COUNT(o.order_id)>1
            )
SELECT ROUND(SUM(number_of_orders)*100/(SELECT COUNT(*) FROM orders),2) AS repeat_orders_percentage
FROM returning_customers;

-- Distribution of orders per customer

WITH count_orders AS (
				SELECT c.customer_unique_id, COUNT(o.order_id) AS number_of_orders
				FROM orders o JOIN customers c ON o.customer_id = c.customer_id
				GROUP BY c.customer_unique_id
				)
SELECT number_of_orders, COUNT(*) AS number_of_customers
FROM count_orders
GROUP BY number_of_orders
ORDER BY number_of_orders;

-- REVENUE

SELECT SUM(price) AS total_product_revenue FROM order_items;
SELECT SUM(price + freight_value) AS total_value_including_freight FROM order_items;

-- Revenue per customer (product value and product value+freight).
SELECT c.customer_unique_id, 
	SUM(oi.price) AS product_revenue_per_customer, 
	SUM(oi.price+oi.freight_value) AS revenue_with_freight
FROM customers c 
	JOIN orders o ON c.customer_id=o.customer_id 
	JOIN order_items oi ON o.order_id=oi.order_id
GROUP BY c.customer_unique_id
ORDER BY product_revenue_per_customer DESC;

-- State analysis: customers, orders, average order value, revenue
SELECT c.customer_state, 
	COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT oi.order_id) AS number_of_orders,
    ROUND(SUM(oi.price)/COUNT(DISTINCT oi.order_id),2) AS aov_by_state,
    SUM(oi.price) AS revenue,
    ROUND(SUM(oi.price)*100/(SELECT SUM(price) FROM order_items),2) AS revenue_share_pct
FROM customers c 
	JOIN orders o ON c.customer_id=o.customer_id
    JOIN order_items oi ON o.order_id=oi.order_id
GROUP BY customer_state
ORDER BY revenue DESC;

