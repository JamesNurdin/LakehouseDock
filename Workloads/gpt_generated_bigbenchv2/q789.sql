WITH
    -- Total quantity sold in stores per category
    category_store_sales AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS total_store_quantity
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    -- Total quantity sold on the web per category
    category_web_sales AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS total_web_quantity
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    -- Average rating and review count per category
    category_reviews AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    -- Distinct customers who bought in stores per category
    category_store_customers AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    -- Distinct customers who bought on the web per category
    category_web_customers AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    -- Revenue per category (price * total quantity sold)
    category_item_revenue AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(
                i.i_price * (
                    COALESCE(ss_qty.total_store_quantity, 0) +
                    COALESCE(ws_qty.total_web_quantity, 0)
                )
            ) AS total_revenue
        FROM items i
        LEFT JOIN (
            SELECT ss_item_id, SUM(ss_quantity) AS total_store_quantity
            FROM store_sales
            GROUP BY ss_item_id
        ) ss_qty ON i.i_item_id = ss_qty.ss_item_id
        LEFT JOIN (
            SELECT ws_item_id, SUM(ws_quantity) AS total_web_quantity
            FROM web_sales
            GROUP BY ws_item_id
        ) ws_qty ON i.i_item_id = ws_qty.ws_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    -- Top‑selling store per category (by quantity sold)
    top_store_per_category AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            s.s_store_id,
            s.s_store_name,
            SUM(ss.ss_quantity) AS category_store_quantity,
            ROW_NUMBER() OVER (
                PARTITION BY i.i_category_id
                ORDER BY SUM(ss.ss_quantity) DESC
            ) AS rn
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY i.i_category_id, i.i_category_name, s.s_store_id, s.s_store_name
    )
SELECT
    cs.i_category_id,
    cs.i_category_name,
    cs.total_store_quantity,
    cw.total_web_quantity,
    (cs.total_store_quantity + cw.total_web_quantity) AS total_quantity,
    rev.avg_rating,
    rev.review_count,
    (csc.distinct_store_customers + cwc.distinct_web_customers) AS distinct_customers,
    revw.total_revenue,
    ts.s_store_name AS top_store_name,
    ts.category_store_quantity AS top_store_quantity
FROM category_store_sales cs
JOIN category_web_sales cw
    ON cs.i_category_id = cw.i_category_id
JOIN category_reviews rev
    ON cs.i_category_id = rev.i_category_id
JOIN category_store_customers csc
    ON cs.i_category_id = csc.i_category_id
JOIN category_web_customers cwc
    ON cs.i_category_id = cwc.i_category_id
JOIN category_item_revenue revw
    ON cs.i_category_id = revw.i_category_id
JOIN top_store_per_category ts
    ON cs.i_category_id = ts.i_category_id
WHERE ts.rn = 1
ORDER BY total_quantity DESC
