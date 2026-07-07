WITH store_rev AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM items i
    JOIN store_sales ss
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_rev AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM items i
    JOIN web_sales ws
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sentiment AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_item_rev AS (
    SELECT
        i.i_item_id,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM items i
    JOIN store_sales ss
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_item_id, s.s_store_id, s.s_store_name
),
top_store AS (
    SELECT
        sir.i_item_id,
        sir.s_store_name,
        sir.store_revenue,
        ROW_NUMBER() OVER (PARTITION BY sir.i_item_id ORDER BY sir.store_revenue DESC) AS rn
    FROM store_item_rev sir
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(sr.store_revenue, 0) + COALESCE(wr.web_revenue, 0) AS total_revenue,
    s.avg_sentiment,
    ts.s_store_name AS top_store,
    ts.store_revenue AS top_store_revenue
FROM items i
LEFT JOIN store_rev sr
    ON i.i_item_id = sr.i_item_id
LEFT JOIN web_rev wr
    ON i.i_item_id = wr.i_item_id
LEFT JOIN sentiment s
    ON i.i_item_id = s.i_item_id
LEFT JOIN top_store ts
    ON i.i_item_id = ts.i_item_id AND ts.rn = 1
WHERE COALESCE(sr.store_revenue, 0) + COALESCE(wr.web_revenue, 0) > 0
ORDER BY total_revenue DESC
LIMIT 10
