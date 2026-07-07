WITH
store_sales_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
sales_total AS (
    SELECT COALESCE(s.i_item_id, w.i_item_id) AS i_item_id,
           COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_qty
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w
        ON s.i_item_id = w.i_item_id
),
reviews_agg AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
customers_per_item AS (
    SELECT ss_item_id AS i_item_id,
           ss_customer_id AS c_customer_id
    FROM store_sales
    UNION
    SELECT ws_item_id AS i_item_id,
           ws_customer_id AS c_customer_id
    FROM web_sales
),
customer_counts AS (
    SELECT i_item_id,
           COUNT(DISTINCT c_customer_id) AS distinct_customer_count
    FROM customers_per_item
    GROUP BY i_item_id
)
SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(COALESCE(st.total_qty, 0)) AS total_quantity_sold,
    AVG(i.i_price) AS average_item_price,
    AVG(r.avg_sentiment) AS average_sentiment,
    SUM(COALESCE(r.review_count, 0)) AS total_reviews,
    SUM(COALESCE(cc.distinct_customer_count, 0)) AS total_distinct_customers
FROM items i
LEFT JOIN sales_total st
    ON i.i_item_id = st.i_item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.i_item_id
LEFT JOIN customer_counts cc
    ON i.i_item_id = cc.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
