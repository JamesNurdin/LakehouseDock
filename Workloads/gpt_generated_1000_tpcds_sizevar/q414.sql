WITH
    store_agg AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            ss.ss_sold_date_sk AS sold_date_sk,
            SUM(ss.ss_ext_sales_price) AS store_sales_amount,
            COUNT(*) AS store_sales_cnt
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
        GROUP BY s.s_store_sk, s.s_store_name, ss.ss_sold_date_sk
    ),
    web_agg AS (
        SELECT
            ws.ws_sold_date_sk AS sold_date_sk,
            SUM(ws.ws_ext_sales_price) AS web_sales_amount,
            COUNT(*) AS web_sales_cnt
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
        GROUP BY ws.ws_sold_date_sk
    ),
    combined AS (
        SELECT
            sa.s_store_sk,
            sa.s_store_name,
            sa.sold_date_sk,
            sa.store_sales_amount,
            wa.web_sales_amount,
            sa.store_sales_cnt,
            wa.web_sales_cnt
        FROM store_agg sa
        FULL OUTER JOIN web_agg wa
            ON sa.sold_date_sk = wa.sold_date_sk
    )
SELECT
    c.s_store_name,
    c.sold_date_sk,
    COALESCE(c.store_sales_amount, 0) AS store_sales_amount,
    COALESCE(c.web_sales_amount, 0) AS web_sales_amount,
    t.top_item_id,
    t.top_item_sales
FROM combined c
LEFT JOIN LATERAL (
    SELECT
        i.i_item_id AS top_item_id,
        SUM(ss.ss_ext_sales_price) AS top_item_sales
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_store_sk = c.s_store_sk
      AND ss.ss_sold_date_sk = c.sold_date_sk
    GROUP BY i.i_item_id
    ORDER BY top_item_sales DESC
    LIMIT 1
) t ON TRUE
WHERE c.s_store_name = (
        SELECT s_store_name
        FROM store
        WHERE s_store_id = 'S_01'
        LIMIT 1
    )
   OR c.s_store_name IS NULL
UNION ALL
SELECT
    'WEB_TOTAL' AS s_store_name,
    wa.sold_date_sk,
    0 AS store_sales_amount,
    wa.web_sales_amount,
    NULL AS top_item_id,
    NULL AS top_item_sales
FROM web_agg wa
WHERE wa.web_sales_amount > (
        SELECT AVG(web_sales_amount)
        FROM web_agg
    )
ORDER BY s_store_name, sold_date_sk
LIMIT 100
