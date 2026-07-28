WITH store_agg AS (
    SELECT
        s.s_store_id AS entity_id,
        t.t_hour AS hour,
        SUM(ss.ss_ext_sales_price) AS sales_amount
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND t.t_hour BETWEEN 8 AND 12
    GROUP BY s.s_store_id, t.t_hour
),
web_agg AS (
    SELECT
        CAST(ws.ws_web_page_sk AS varchar) AS entity_id,
        t.t_hour AS hour,
        SUM(ws.ws_ext_sales_price) AS sales_amount
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_contract = 'fop0bcSd91J26IVpR'
      AND t.t_hour BETWEEN 8 AND 12
    GROUP BY ws.ws_web_page_sk, t.t_hour
),
combined AS (
    SELECT 'store' AS channel, entity_id, hour, sales_amount
    FROM store_agg
    UNION ALL
    SELECT 'web' AS channel, entity_id, hour, sales_amount
    FROM web_agg
)
SELECT
    channel,
    entity_id,
    hour,
    sales_amount,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY sales_amount DESC) AS rank_in_channel
FROM combined
ORDER BY channel, sales_amount DESC
LIMIT 100
