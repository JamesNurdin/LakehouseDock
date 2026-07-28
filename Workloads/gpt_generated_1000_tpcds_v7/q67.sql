SELECT
    channel,
    entity_name,
    year,
    total_net_profit
FROM (
    SELECT
        'store' AS channel,
        s.s_store_name AS entity_name,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE s.s_manager = 'David Thomas'
      AND d.d_year = 2002
    GROUP BY s.s_store_name, d.d_year

    UNION ALL

    SELECT
        'web' AS channel,
        wp.wp_type AS entity_name,
        d.d_year AS year,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE wp.wp_type = 'c'
      AND d.d_year = 2002
    GROUP BY wp.wp_type, d.d_year
) AS combined
ORDER BY total_net_profit DESC
LIMIT 100
