USE olist;

-- Revenue % from returning customers (price)
WITH returning AS(
			SELECT c.customer_unique_id, COUNT(o.order_id) AS number_of_orders
			FROM orders o JOIN customers c ON o.customer_id = c.customer_id
			GROUP BY c.customer_unique_id
			HAVING COUNT(o.order_id)>1
            )
SELECT 
	SUM(oi.price) AS revenue_from_returning, 
    ROUND(SUM(oi.price)*100/(SELECT SUM(price) AS total_product_value FROM order_items),2) AS percentage_of_total
FROM returning r 
	JOIN customers c ON r.customer_unique_id=c.customer_unique_id
	JOIN orders o ON c.customer_id=o.customer_id 
	JOIN order_items oi ON o.order_id=oi.order_id
;
-- Result 5.73%

-- AOV
WITH order_values AS(
			SELECT o.order_id, SUM(price) AS order_value
			FROM orders o 
				JOIN order_items oi ON o.order_id=oi.order_id
			GROUP BY o.order_id
            )
SELECT ROUND(AVG(order_value),2) AS aov
FROM order_values;
-- Result 137.75

-- AOV for returning customers
WITH returning AS(
			SELECT c.customer_unique_id, COUNT(o.order_id) AS number_of_orders
			FROM orders o JOIN customers c ON o.customer_id = c.customer_id
			GROUP BY c.customer_unique_id
			HAVING COUNT(o.order_id)>1
            ),
	order_values AS(
			SELECT o.order_id, SUM(price) AS order_value
			FROM orders o 
				JOIN order_items oi ON o.order_id=oi.order_id
			GROUP BY o.order_id
            )
SELECT ROUND(AVG(ov.order_value),2) AS aov_returning
FROM order_values ov
	JOIN orders o ON ov.order_id = o.order_id
    JOIN customers c ON c.customer_id=o.customer_id
    JOIN returning r ON c.customer_unique_id=r.customer_unique_id;
    -- Result 124.91
    -- Observation: Lower than AOV for non-returning customers (138.62).
    
-- AOV for non-returning customers
WITH nonreturning AS(
			SELECT c.customer_unique_id, COUNT(o.order_id) AS number_of_orders
			FROM orders o JOIN customers c ON o.customer_id = c.customer_id
			GROUP BY c.customer_unique_id
			HAVING COUNT(o.order_id)=1
            ),
	order_values AS(
			SELECT o.order_id, SUM(price) AS order_value
			FROM orders o 
				JOIN order_items oi ON o.order_id=oi.order_id
			GROUP BY o.order_id
            )
SELECT ROUND(AVG(ov.order_value),2) AS aov_nonreturning
FROM order_values ov
	JOIN orders o ON ov.order_id = o.order_id
    JOIN customers c ON c.customer_id=o.customer_id
    JOIN nonreturning nr ON c.customer_unique_id=nr.customer_unique_id;
-- Result 138.62

-- order value depending on how many items were ordered
WITH per_order AS (
			SELECT order_id, COUNT(*) AS number_of_items, SUM(price) AS order_value
			FROM order_items
			GROUP BY order_id
			)
SELECT number_of_items, COUNT(*) AS number_of_orders, ROUND(AVG(order_value),2) AS avg_order_value
FROM per_order
GROUP BY number_of_items 
ORDER BY number_of_items;

-- avg value per item depending on how many items were ordered
WITH per_order AS (
			SELECT order_id, 
					COUNT(*) AS number_of_items, 
                    SUM(price) AS order_value, 
                    SUM(price)/COUNT(*) AS avg_product_value
			FROM order_items
			GROUP BY order_id
			)
SELECT number_of_items, 
		COUNT(*) AS number_of_orders, 
        ROUND(AVG(order_value),2) AS avg_order_value, 
        ROUND(AVG(avg_product_value),2) AS avg_item_value_per_order
FROM per_order
GROUP BY number_of_items 
ORDER BY number_of_items;

-- ORDER STATUS

SELECT order_status, COUNT(*) AS number_of_orders
FROM orders 
GROUP BY order_status
ORDER BY number_of_orders DESC;

-- checking meaning of order status
WITH count_dates AS(
			SELECT order_status, 
					CASE WHEN order_purchase_timestamp IS NOT NULL THEN 1 ELSE 0 END AS order_purchase,
					CASE WHEN order_approved_at IS NOT NULL THEN 1 ELSE 0 END AS order_approved,
					CASE WHEN order_delivered_carrier_date IS NOT NULL THEN 1 ELSE 0 END AS order_carrier,
					CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END AS order_delivered
			FROM orders
            )
SELECT order_status, 
		COUNT(*) AS number_of_orders,
		SUM(order_purchase) AS purchase,
        SUM(order_approved) AS approved,
        SUM(order_carrier) AS carrier,
        SUM(order_delivered) AS delivered
FROM count_dates
GROUP BY order_status;

-- Checking canceled but delivered orders
SELECT *
FROM orders
WHERE order_status = 'canceled'
  AND order_delivered_customer_date IS NOT NULL;

-- Distribution depending on days to delivery
WITH delivery_days AS(
			SELECT order_id, order_purchase_timestamp, order_delivered_customer_date, 
				DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS days_to_delivery
			FROM orders
			WHERE order_status='delivered' AND order_delivered_customer_date IS NOT NULL
            )
SELECT days_to_delivery, COUNT(*) AS number_of_orders
FROM delivery_days
GROUP BY days_to_delivery
ORDER BY days_to_delivery;

-- distribution by lead time, grouped

WITH delivery_days AS(
			SELECT order_id, order_purchase_timestamp, order_delivered_customer_date, 
				DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS days_to_delivery
			FROM orders
			WHERE order_status='delivered' AND order_delivered_customer_date IS NOT NULL
            ),
	distribution AS(
			SELECT days_to_delivery, 
				CASE 
					WHEN days_to_delivery <= 3 THEN '00-3 days'
                    WHEN days_to_delivery <= 7 THEN '04-7 days'
                    WHEN days_to_delivery <= 14 THEN '08-14 days'
                    WHEN days_to_delivery <= 21 THEN '15-21 days'
                    WHEN days_to_delivery <= 30 THEN '22-30 days'
                    ELSE '31+ days'
                    END AS lead_time
			FROM delivery_days
            )
SELECT lead_time, 
	COUNT(*) AS number_of_orders,
    ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(),2) AS percentage_of_delivered
FROM distribution
GROUP BY lead_time
ORDER BY lead_time;

-- Average days to delivery
SELECT AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS avg_days_to_delivery
FROM orders
WHERE order_status='delivered' AND order_delivered_customer_date IS NOT NULL;

-- Median of days to delivery
WITH delivery_days AS(
			SELECT order_id, order_purchase_timestamp, order_delivered_customer_date, 
				DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS days_to_delivery
			FROM orders
			WHERE order_status='delivered' AND order_delivered_customer_date IS NOT NULL
			),
	numbered AS(
			SELECT  order_id, order_purchase_timestamp, order_delivered_customer_date, days_to_delivery, 
				ROW_NUMBER() OVER(ORDER BY days_to_delivery) AS rownumber,
                COUNT(*)OVER() AS total_delivered
			FROM delivery_days
            )
SELECT AVG(days_to_delivery) AS median_days_to_delivery
FROM numbered
WHERE IF(
	total_delivered % 2=0, 
    rownumber=total_delivered/2 OR rownumber=total_delivered/2 +1, 
    rownumber=(total_delivered+1)/2);
-- Delivery time is right-skewed: median = 10 days, average ≈ 12.5 days.


-- average difference between estimated and actual delivery date
WITH counted_difference AS(
			SELECT order_id,order_delivered_customer_date, order_estimated_delivery_date,
					DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) AS diff_estimated_delivered
			FROM orders
			WHERE order_status='delivered' 
				AND order_delivered_customer_date IS NOT NULL 
                AND order_estimated_delivery_date IS NOT NULL
            )
SELECT AVG(diff_estimated_delivered) AS average_estimated_delivery_difference
FROM counted_difference;

-- Distribution

-- grouped distribution with percentage of all delivered orders

WITH counted_difference AS(
			SELECT order_id,order_delivered_customer_date, order_estimated_delivery_date,
					DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) AS diff_estimated_delivered
			FROM orders
			WHERE order_status='delivered' AND order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL
            ),
	distribution AS(
			SELECT diff_estimated_delivered, 
				CASE 
					WHEN diff_estimated_delivered < 0 THEN '_early'
					WHEN diff_estimated_delivered = 0 THEN '_on_time'
                    WHEN diff_estimated_delivered <= 7 THEN '01-7_late'
                    WHEN diff_estimated_delivered <= 14 THEN '08-14_late'
                    WHEN diff_estimated_delivered <= 30 THEN '15-30_late'
                    ELSE '31+_late'
                    END AS dlv_time
			FROM counted_difference
            )
SELECT dlv_time, 
	COUNT(*) AS number_of_orders,
    ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(),2) AS percentage_of_delivered
FROM distribution
GROUP BY dlv_time
ORDER BY dlv_time;
	
-- Approval time    
-- Average
WITH approval_time AS(
			SELECT order_id, order_purchase_timestamp, order_approved_at, 
				TIMESTAMPDIFF(MINUTE, order_purchase_timestamp, order_approved_at) AS minutes_to_approve
			FROM orders
			WHERE order_purchase_timestamp IS NOT NULL AND order_approved_at IS NOT NULL
            )
SELECT AVG(minutes_to_approve) AS avg_approval_time_minutes
FROM approval_time;

-- median from approval time
WITH approval_time AS(
			SELECT order_id, 
				TIMESTAMPDIFF(MINUTE, order_purchase_timestamp, order_approved_at) AS minutes_to_approve
			FROM orders
			WHERE order_purchase_timestamp IS NOT NULL AND order_approved_at IS NOT NULL
            ),
	numbered AS(
			SELECT minutes_to_approve,
				ROW_NUMBER() OVER(ORDER BY minutes_to_approve) AS rownum,
                COUNT(*) OVER() AS total_approved
			FROM approval_time
            )
SELECT AVG(minutes_to_approve) AS median_approval_time
FROM numbered
WHERE rownum IN (FLOOR((total_approved+1)/2), CEIL((total_approved+1)/2));

-- Distribution by time to approve, grouped 

WITH approved_in AS(
			SELECT order_id,
				TIMESTAMPDIFF(MINUTE, order_purchase_timestamp, order_approved_at) AS app_minutes
			FROM orders
			WHERE order_purchase_timestamp IS NOT NULL AND order_approved_at IS NOT NULL
            ),
	distribution AS(
			SELECT app_minutes, 
				CASE 
					WHEN app_minutes <= 15 THEN '00-15 minutes'
					WHEN app_minutes <=30 THEN '0016-30 minutes'
                    WHEN app_minutes <=60  THEN '0031-60 minutes'
                    WHEN app_minutes <= 180 THEN '01-3 hours'
                    WHEN app_minutes <= 360 THEN '03-6 hours'
                    WHEN app_minutes <= 24*60 THEN '06-24 hours'
                    WHEN app_minutes <= 24*60*3 THEN '1-3 days'
                    WHEN app_minutes <= 24*60*7 THEN '3-7 days'
                    ELSE '8+days'
                    END AS approval_time
			FROM approved_in
            )
SELECT approval_time, 
	COUNT(*) AS number_of_orders,
    ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(),2) AS percentage_of_approved
FROM distribution
GROUP BY approval_time
ORDER BY approval_time;

-- Approval to carrier time.
-- For process-time analysis, only logically ordered timestamps are included. 
-- 1,359 records(~1.4% of all) with approval time later than delivered_carrier time are excluded.

-- Average
SELECT AVG(TIMESTAMPDIFF(MINUTE, order_approved_at, order_delivered_carrier_date)) AS average_app_carr_minutes
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL AND order_approved_at IS NOT NULL AND order_approved_at<=order_delivered_carrier_date;

-- distribution grouped

WITH app_carr_minutes AS(
			SELECT order_id, order_approved_at, order_delivered_carrier_date,
					TIMESTAMPDIFF(MINUTE, order_approved_at, order_delivered_carrier_date) AS app_carrier_minutes
			FROM orders
			WHERE order_delivered_carrier_date IS NOT NULL AND order_approved_at IS NOT NULL AND order_approved_at<=order_delivered_carrier_date
            ),
	distribution AS(
			SELECT app_carrier_minutes, 
				CASE 
                    WHEN app_carrier_minutes <=60  THEN '00-60 minutes'
                    WHEN app_carrier_minutes <= 360 THEN '01-6 hours'
                    WHEN app_carrier_minutes <= 24*60 THEN '06-24 hours'
                    WHEN app_carrier_minutes <= 24*60*3 THEN '1-3 days'
                    WHEN app_carrier_minutes <= 24*60*7 THEN '3-7 days'
					WHEN app_carrier_minutes <= 24*60*14 THEN '8-14 days'
                    ELSE 'more than 14 days'
                    END AS app_carr_time
			FROM app_carr_minutes
            )
SELECT app_carr_time, 
	COUNT(*) AS number_of_orders,
    ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(),2) AS percentage_of_total
FROM distribution
GROUP BY app_carr_time
ORDER BY app_carr_time;

-- Median approval-carrier time

WITH app_carr_minutes AS(
			SELECT order_id, order_approved_at, order_delivered_carrier_date,
					TIMESTAMPDIFF(MINUTE, order_approved_at, order_delivered_carrier_date) AS app_carrier_minutes
			FROM orders
			WHERE order_delivered_carrier_date IS NOT NULL 
				AND order_approved_at IS NOT NULL 
                AND order_approved_at<=order_delivered_carrier_date
            ),
	numbered AS(
			SELECT app_carrier_minutes,
				ROW_NUMBER() OVER(ORDER BY app_carrier_minutes) AS rownum,
                COUNT(*) OVER() AS total_app_carr
			FROM app_carr_minutes
            )
SELECT AVG(app_carrier_minutes) AS median_app_carr_minutes
FROM numbered
WHERE rownum IN (FLOOR((total_app_carr+1)/2), CEIL((total_app_carr+1)/2));

-- average

SELECT ROUND(AVG(TIMESTAMPDIFF(MINUTE, order_delivered_carrier_date, order_delivered_customer_date))/60/24,2) AS avg_dlv_days
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL 
	AND order_delivered_customer_date IS NOT NULL 
    AND order_delivered_carrier_date <= order_delivered_customer_date;
    
-- distribution grouped

WITH carr_dlv_minutes AS(
			SELECT order_id, order_delivered_carrier_date, order_delivered_customer_date,
				TIMESTAMPDIFF(MINUTE, order_delivered_carrier_date, order_delivered_customer_date) AS delivery_minutes
			FROM orders
			WHERE order_delivered_carrier_date IS NOT NULL 
				AND order_delivered_customer_date IS NOT NULL 
				AND order_delivered_carrier_date <= order_delivered_customer_date),
	distribution AS(
			SELECT delivery_minutes, 
				CASE 
                    WHEN delivery_minutes <= 24*60 THEN '00-24 hours'
                    WHEN delivery_minutes <= 24*60*2 THEN '01-2 days'
                    WHEN delivery_minutes <= 24*60*4 THEN '03-4 days'                    
                    WHEN delivery_minutes <= 24*60*7 THEN '05-7 days'
					WHEN delivery_minutes <= 24*60*10 THEN '08-10 days'
					WHEN delivery_minutes <= 24*60*14 THEN '11-14 days'
                    WHEN delivery_minutes <= 24*60*21 THEN '15-21 days'
                    WHEN delivery_minutes <= 24*60*30 THEN '22-30 days'
                    ELSE '31 days and more'
                    END AS carr_dlv_time
			FROM carr_dlv_minutes
            )
SELECT carr_dlv_time, 
	COUNT(*) AS number_of_orders,
    ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(),2) AS percentage_of_total
FROM distribution
GROUP BY carr_dlv_time
ORDER BY carr_dlv_time;

-- Median carrier-customer time

WITH carr_dlv_minutes AS(
			SELECT order_id, order_delivered_carrier_date, order_delivered_customer_date,
				TIMESTAMPDIFF(MINUTE, order_delivered_carrier_date, order_delivered_customer_date) AS delivery_minutes
			FROM orders
			WHERE order_delivered_carrier_date IS NOT NULL 
				AND order_delivered_customer_date IS NOT NULL 
				AND order_delivered_carrier_date <= order_delivered_customer_date
                ),
	numbered AS(
			SELECT delivery_minutes,
				ROW_NUMBER() OVER(ORDER BY delivery_minutes) AS rownum,
                COUNT(*) OVER() AS total_carr_dlv
			FROM carr_dlv_minutes
            )
SELECT AVG(delivery_minutes) AS median_carr_dlv_minutes
FROM numbered
WHERE rownum IN (FLOOR((total_carr_dlv+1)/2), CEIL((total_carr_dlv+1)/2));


-- MONTHLY ANALYSIS

SELECT * 
FROM orders o LEFT JOIN order_items oi ON o.order_id=oi.order_id
WHERE oi.order_id IS NULL;

SELECT order_status, COUNT(*)
FROM orders o LEFT JOIN order_items oi ON o.order_id=oi.order_id
WHERE oi.order_id IS NULL
GROUP BY order_status;
-- 775 orders have no corresponding order_items records and are therefore excluded from item-level and revenue analyses.

-- Monthly revenue and number of ordered products
SELECT YEAR(o.order_purchase_timestamp) AS yr,
	MONTH(o.order_purchase_timestamp) AS mth,
    SUM(oi.price) AS revenue,
    COUNT(oi.product_id) AS ordered_products
FROM orders o JOIN order_items oi ON o. order_id=oi.order_id
GROUP BY yr,mth
ORDER BY yr,mth;

-- Monthly number of orders and AOV
SELECT YEAR(o.order_purchase_timestamp) AS yr,
	MONTH(o.order_purchase_timestamp) AS mth,
    SUM(oi.price) AS revenue,
    COUNT(DISTINCT oi.order_id) AS number_of_orders,
    ROUND(SUM(oi.price)/COUNT(DISTINCT oi.order_id),2) AS aov
FROM orders o JOIN order_items oi ON o. order_id=oi.order_id
GROUP BY yr,mth
ORDER BY yr,mth;
