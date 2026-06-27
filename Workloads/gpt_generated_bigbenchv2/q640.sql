WITH store_agg AS (
    SELECT
        ss.ss_item_id,
        ss.ss_store_id,
        i.i_name,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY
        ss.ss_item_id,
        ss.ss_store_id,
        i.i_name,
        i.i_category_name
),
web_agg AS (
    SELECT
        ws.ws_item_id,
        i.i_name,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        ws.ws_item_id,
        i.i_name,
        i.i_category_name
)
SELECT
    sa.ss_item_id,
    sa.i_name,
    sa.i_category_name,
    s.s_store_name,
    sa.store_quantity,
    sa.store_revenue,
    wa.web_quantity,
    wa.web_revenue,
    (sa.store_quantity + wa.web_quantity) AS total_quantity,
    (sa.store_revenue + wa.web_revenue) AS total_revenue,
    CASE WHEN sa.store_quantity > 0 THEN sa.store_revenue / sa.store_quantity ELSE 0 END AS store_avg_price,
    CASE WHEN wa.web_quantity > 0 THEN wa.web_revenue / wa.web_quantity ELSE 0 END AS web_avg_price,
    CASE WHEN (sa.store_quantity + wa.web_quantity) > 0 THEN (sa.store_revenue + wa.web_revenue) / (sa.store_quantity + wa.web_quantity) ELSE 0 END AS overall_avg_price
FROM store_agg sa
JOIN web_agg wa
    ON sa.ss_item_id = wa.ws_item_id
JOIN stores s
    ON sa.ss_store_id = s.s_store_id
WHERE (sa.store_quantity + wa.web_quantity) >= 10
ORDER BY total_quantity DESC
LIMIT 100
