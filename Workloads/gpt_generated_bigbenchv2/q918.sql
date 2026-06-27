WITH store_agg AS (
    SELECT
        i.i_category_name AS i_category_name,
        s.s_store_name AS s_store_name,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt,
        AVG(i.i_price) AS avg_price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_name, s.s_store_name
),
web_agg AS (
    SELECT
        i.i_category_name AS i_category_name,
        'Web' AS store_name,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt,
        AVG(i.i_price) AS avg_price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_name
)
SELECT
    COALESCE(sa.i_category_name, wa.i_category_name) AS category,
    COALESCE(sa.s_store_name, wa.store_name) AS store_or_channel,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_customer_cnt, 0) AS store_customer_cnt,
    COALESCE(wa.web_customer_cnt, 0) AS web_customer_cnt,
    COALESCE(sa.avg_price, wa.avg_price) AS avg_price
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.i_category_name = wa.i_category_name
ORDER BY category, store_or_channel
