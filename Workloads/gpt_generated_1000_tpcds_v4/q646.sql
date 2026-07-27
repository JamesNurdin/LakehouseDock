WITH store_sales_agg AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
)
SELECT
    combined.t_hour,
    combined.ca_state,
    combined.web_name,
    SUM(CASE WHEN combined.channel = 'store' THEN combined.ext_sales_price ELSE 0 END) AS store_sales,
    SUM(CASE WHEN combined.channel = 'store' THEN combined.net_profit ELSE 0 END) AS store_profit,
    SUM(CASE WHEN combined.channel = 'web'   THEN combined.ext_sales_price ELSE 0 END) AS web_sales,
    SUM(CASE WHEN combined.channel = 'web'   THEN combined.net_profit      ELSE 0 END) AS web_profit,
    COUNT(*) AS txn_count
FROM (
    -- Store channel rows
    SELECT
        ss_agg.ss_ext_sales_price        AS ext_sales_price,
        ss_agg.ss_net_profit             AS net_profit,
        ca_ss.ca_state                    AS ca_state,
        t_ss.t_hour                       AS t_hour,
        'store'                           AS channel,
        CAST(NULL AS varchar)            AS web_name
    FROM store_sales_agg ss_agg
    JOIN time_dim t_ss          ON ss_agg.ss_sold_time_sk = t_ss.t_time_sk
    JOIN customer_address ca_ss ON ss_agg.ss_addr_sk      = ca_ss.ca_address_sk
    JOIN store s                ON ss_agg.ss_store_sk    = s.s_store_sk
    JOIN store s_dup            ON ss_agg.ss_store_sk    = s_dup.s_store_sk          -- duplicate join
    JOIN time_dim t_dup        ON ss_agg.ss_sold_time_sk = t_dup.t_time_sk          -- duplicate join

    UNION ALL

    -- Web channel rows
    SELECT
        ws.ws_ext_sales_price   AS ext_sales_price,
        ws.ws_net_profit        AS net_profit,
        ca_ws_bill.ca_state     AS ca_state,
        t_ws.t_hour             AS t_hour,
        'web'                   AS channel,
        ws_site.web_name        AS web_name
    FROM web_sales ws
    JOIN time_dim t_ws               ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk  = ca_ws_bill.ca_address_sk
    JOIN web_site ws_site            ON ws.ws_web_site_sk   = ws_site.web_site_sk
    JOIN web_site ws_site_dup        ON ws.ws_web_site_sk   = ws_site_dup.web_site_sk   -- duplicate join
    JOIN time_dim t_ws_dup           ON ws.ws_sold_time_sk = t_ws_dup.t_time_sk      -- duplicate join
) AS combined
WHERE EXISTS (
    SELECT 1
    FROM store st
    WHERE st.s_state = combined.ca_state
      AND st.s_number_employees > 200
)
GROUP BY combined.t_hour, combined.ca_state, combined.web_name
ORDER BY store_sales DESC
LIMIT 100
