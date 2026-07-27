WITH store_agg AS (
    SELECT 
        d.d_year AS sales_year,
        s.s_store_name AS location_name,
        SUM(ss.ss_net_profit) AS total_profit,
        'Store' AS sales_channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND ss.ss_quantity > 0
    GROUP BY d.d_year, s.s_store_name
),
web_agg AS (
    SELECT 
        d.d_year AS sales_year,
        wp.wp_url AS location_name,
        SUM(ws.ws_net_profit) AS total_profit,
        'Web' AS sales_channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND wp.wp_char_count > 4000
    GROUP BY d.d_year, wp.wp_url
)
SELECT sales_year, location_name, total_profit, sales_channel
FROM store_agg
UNION ALL
SELECT sales_year, location_name, total_profit, sales_channel
FROM web_agg
ORDER BY sales_year DESC, total_profit DESC
LIMIT 100
