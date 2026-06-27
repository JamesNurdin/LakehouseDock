/*
  Analytical query: Top 10 customers by combined store and web revenue,
  showing purchase volumes, distinct items bought, average rating of purchased items,
  and total number of reviews for those items.
*/
WITH store_cust AS (
    SELECT
        ss.ss_customer_id AS c_customer_id,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_rev,
        COUNT(DISTINCT ss.ss_item_id) AS store_distinct_items
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_customer_id
),
web_cust AS (
    SELECT
        ws.ws_customer_id AS c_customer_id,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_rev,
        COUNT(DISTINCT ws.ws_item_id) AS web_distinct_items
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_customer_id
),
item_rating AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
cust_item_rating AS (
    SELECT
        ss.ss_customer_id AS c_customer_id,
        SUM(ss.ss_quantity * ir.avg_rating) AS weighted_rating_sum,
        SUM(ss.ss_quantity) AS rating_qty_sum
    FROM store_sales ss
    JOIN item_rating ir ON ss.ss_item_id = ir.i_item_id
    GROUP BY ss.ss_customer_id

    UNION ALL

    SELECT
        ws.ws_customer_id AS c_customer_id,
        SUM(ws.ws_quantity * ir.avg_rating) AS weighted_rating_sum,
        SUM(ws.ws_quantity) AS rating_qty_sum
    FROM web_sales ws
    JOIN item_rating ir ON ws.ws_item_id = ir.i_item_id
    GROUP BY ws.ws_customer_id
),
cust_rating AS (
    SELECT
        c_customer_id,
        SUM(weighted_rating_sum) / NULLIF(SUM(rating_qty_sum), 0) AS avg_item_rating
    FROM cust_item_rating
    GROUP BY c_customer_id
),
cust_review_raw AS (
    SELECT
        ss.ss_customer_id AS c_customer_id,
        SUM(ir.review_cnt) AS review_cnt_sum
    FROM store_sales ss
    JOIN item_rating ir ON ss.ss_item_id = ir.i_item_id
    GROUP BY ss.ss_customer_id

    UNION ALL

    SELECT
        ws.ws_customer_id AS c_customer_id,
        SUM(ir.review_cnt) AS review_cnt_sum
    FROM web_sales ws
    JOIN item_rating ir ON ws.ws_item_id = ir.i_item_id
    GROUP BY ws.ws_customer_id
),
cust_review AS (
    SELECT
        c_customer_id,
        SUM(review_cnt_sum) AS total_review_cnt
    FROM cust_review_raw
    GROUP BY c_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(sc.store_qty, 0) AS store_qty,
    COALESCE(sc.store_rev, 0) AS store_rev,
    COALESCE(wc.web_qty, 0) AS web_qty,
    COALESCE(wc.web_rev, 0) AS web_rev,
    COALESCE(sc.store_distinct_items, 0) + COALESCE(wc.web_distinct_items, 0) AS total_distinct_items,
    cr.avg_item_rating,
    crv.total_review_cnt
FROM customers c
LEFT JOIN store_cust sc ON c.c_customer_id = sc.c_customer_id
LEFT JOIN web_cust wc ON c.c_customer_id = wc.c_customer_id
LEFT JOIN cust_rating cr ON c.c_customer_id = cr.c_customer_id
LEFT JOIN cust_review crv ON c.c_customer_id = crv.c_customer_id
ORDER BY (COALESCE(sc.store_rev, 0) + COALESCE(wc.web_rev, 0)) DESC
LIMIT 10
