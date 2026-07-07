WITH store_sales_agg AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        SUM(ss.ss_quantity * i.i_price) AS store_spend,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_customer_id
),
web_sales_agg AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        SUM(ws.ws_quantity * i.i_price) AS web_spend,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_customer_id
),
reviews_agg AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY ss.ss_customer_id
    UNION ALL
    SELECT
        ws.ws_customer_id AS customer_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY ws.ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(ssa.store_spend, 0) + COALESCE(wsa.web_spend, 0) AS total_spend,
    COALESCE(ssa.store_qty, 0) + COALESCE(wsa.web_qty, 0) AS total_quantity,
    AVG(r.avg_sentiment) AS avg_review_sentiment
FROM customers c
LEFT JOIN store_sales_agg ssa ON c.c_customer_id = ssa.customer_id
LEFT JOIN web_sales_agg wsa ON c.c_customer_id = wsa.customer_id
LEFT JOIN reviews_agg r ON c.c_customer_id = r.customer_id
GROUP BY
    c.c_customer_id,
    c.c_name,
    ssa.store_spend,
    ssa.store_qty,
    wsa.web_spend,
    wsa.web_qty
ORDER BY total_spend DESC
LIMIT 50
