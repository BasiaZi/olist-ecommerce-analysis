USE olist;

SELECT product_category_name, COUNT(*) AS number_of_products
FROM products
GROUP BY product_category_name
ORDER BY number_of_products DESC;

-- Revenue, number of sold product units and average selling price by category
SELECT product_category_name, 
	COUNT(*) AS number_of_ordered_products, 
	SUM(price) AS revenue_by_category, 
    ROUND(AVG(price),2) AS avg_price_per_product
FROM products p JOIN order_items oi ON p.product_id=oi.product_id
GROUP BY product_category_name
ORDER BY revenue_by_category DESC;

SELECT COUNT(product_id), COUNT(DISTINCT product_id)
FROM products;

-- Most ordered products with revenue by product, sorted by most ordered
SELECT p.product_id, p.product_category_name,
	COUNT(*) AS number_of_ordered_products, 
	SUM(oi.price) AS revenue_by_product
FROM products p JOIN order_items oi ON p.product_id=oi.product_id
GROUP BY p.product_id, p.product_category_name
ORDER BY number_of_ordered_products DESC;

-- Most ordered products with revenue by product, sorted by revenue
SELECT p.product_id, p.product_category_name,
	COUNT(*) AS number_of_ordered_products, 
	SUM(oi.price) AS revenue_by_product
FROM products p JOIN order_items oi ON p.product_id=oi.product_id
GROUP BY p.product_id, p.product_category_name
ORDER BY revenue_by_product DESC;

-- Different prices for same product_id check
SELECT p.product_id, 
	COUNT(DISTINCT oi.price) AS number_of_diff_prices,
    MIN(oi.price) AS minimum_price,
	MAX(oi.price) AS maximum_price
FROM products p JOIN order_items oi ON p.product_id=oi.product_id
GROUP BY p.product_id
HAVING number_of_diff_prices>1
ORDER BY p.product_id;

-- Revenue share of the top 10% of products ranked by revenue
WITH product_revenue AS(
			SELECT p.product_id, 
					SUM(oi.price) AS revenue_by_product,
                    NTILE(10) OVER (ORDER BY SUM(oi.price) DESC) AS percentile10
			FROM products p JOIN order_items oi ON p.product_id=oi.product_id
			GROUP BY p.product_id
            )
SELECT SUM(revenue_by_product) AS 'revenue_top10%', 
	ROUND(SUM(revenue_by_product)*100/(SELECT SUM(price) FROM order_items),2) AS perc_of_total
FROM product_revenue
WHERE percentile10=1;

-- Revenue share of the top 5% of products ranked by revenue
WITH product_revenue AS(
			SELECT p.product_id, 
					SUM(oi.price) AS revenue_by_product,
                    NTILE(20) OVER (ORDER BY SUM(oi.price) DESC) AS percentile20
			FROM products p JOIN order_items oi ON p.product_id=oi.product_id
			GROUP BY p.product_id
            )
SELECT SUM(revenue_by_product) AS 'revenue_top5%', 
	ROUND(SUM(revenue_by_product)*100/(SELECT SUM(price) FROM order_items),2) AS perc_of_total
FROM product_revenue
WHERE percentile20=1;

-- checking consistency of data in products and order items tables
SELECT p.product_category_name, 
	COUNT(DISTINCT p.product_id) AS num_of_products,
    COUNT(DISTINCT oi.product_id) AS num_of_different_ordered_products,
    COUNT(DISTINCT p.product_id) - COUNT(DISTINCT oi.product_id) AS difference
FROM products p LEFT JOIN order_items oi ON p.product_id=oi.product_id
GROUP BY product_category_name;

-- Revenue by product inside category
WITH product_revenue AS(
			SELECT p.product_id, p.product_category_name, SUM(oi.price) AS revenue_by_product
			FROM products p JOIN order_items oi ON p.product_id=oi.product_id
            GROUP BY p.product_id, p.product_category_name
            ),
	ranked AS(
			SELECT product_category_name, product_id, revenue_by_product,
				SUM(revenue_by_product) OVER(PARTITION BY product_category_name) AS revenue_by_category,
				ROW_NUMBER() OVER (PARTITION BY product_category_name ORDER BY revenue_by_product DESC, product_id) AS rank_in_category
			FROM product_revenue
            )
SELECT *, 
	ROUND(revenue_by_product*100/revenue_by_category,2) AS '% of category revenue'
FROM ranked
WHERE rank_in_category<=3;

-- Revenue of top3 by category
WITH product_revenue AS(
			SELECT p.product_id, p.product_category_name, SUM(oi.price) AS revenue_by_product
			FROM products p JOIN order_items oi ON p.product_id=oi.product_id
            GROUP BY p.product_id, p.product_category_name
            ),
	ranked AS(
			SELECT product_category_name, product_id, revenue_by_product,
				SUM(revenue_by_product) OVER(PARTITION BY product_category_name) AS revenue_by_category,
                COUNT(product_id) OVER (PARTITION BY product_category_name) AS num_products_in_cat,
				ROW_NUMBER() OVER (PARTITION BY product_category_name ORDER BY revenue_by_product DESC, product_id) AS rank_in_category
			FROM product_revenue
            ),
	top3 AS(
			SELECT *, 
			ROUND(revenue_by_product*100/revenue_by_category,2) AS perc_of_category_revenue
			FROM ranked
			WHERE rank_in_category<=3
            )
SELECT product_category_name, 
	revenue_by_category, 
    num_products_in_cat, 
    SUM(revenue_by_product) AS 'top3 revenue',
    SUM(perc_of_category_revenue) AS 'top3 % of category'
FROM top3
GROUP BY product_category_name, 
	revenue_by_category, 
    num_products_in_cat
ORDER BY revenue_by_category DESC;