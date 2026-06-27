/*
  Analytical query: For each item category, compute offline and online sales quantities,
  distinct customers, average rating, review count, average price, and total quantity.
*/
WITH offline_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS offline_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS offline_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
online_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS online_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS online_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
price_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(i.i_price) AS avg_price
    FROM items i
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    off.i_category_name AS category_name,
    off.offline_quantity,
    onl.online_quantity,
    off.offline_customers,
    onl.online_customers,
    rev.avg_rating,
    rev.review_count,
    prc.avg_price,
    (off.offline_quantity + onl.online_quantity) AS total_quantity
FROM offline_sales off
JOIN online_sales onl
    ON off.i_category_id = onl.i_category_id
    AND off.i_category_name = onl.i_category_name
JOIN reviews rev
    ON off.i_category_id = rev.i_category_id
    AND off.i_category_name = rev.i_category_name
JOIN price_agg prc
    ON off.i_category_id = prc.i_category_id
    AND off.i_category_name = prc.i_category_name
ORDER BY total_quantity DESC
