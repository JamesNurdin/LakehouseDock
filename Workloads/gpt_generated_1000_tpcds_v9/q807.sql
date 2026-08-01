WITH store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS biz_date_sk,
        i.i_item_id AS item_id,
        SUM(ss.ss_net_paid) AS total_sales,
        'store' AS sales_source
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'TX'
      AND t.t_hour BETWEEN 8 AND 12
    GROUP BY ss.ss_sold_date_sk, i.i_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS biz_date_sk,
        i.i_item_id AS item_id,
        SUM(ws.ws_net_paid) AS total_sales,
        'web' AS sales_source
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_state = 'TX'
      AND t.t_hour BETWEEN 8 AND 12
    GROUP BY ws.ws_sold_date_sk, i.i_item_id
),
combined AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    biz_date_sk,
    item_id,
    total_sales,
    sales_source,
    ROW_NUMBER() OVER (PARTITION BY biz_date_sk ORDER BY total_sales DESC) AS rank_per_date
FROM combined
ORDER BY biz_date_sk DESC, rank_per_date
LIMIT 100
