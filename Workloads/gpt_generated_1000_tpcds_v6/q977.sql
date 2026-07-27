WITH sold_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        ws.ws_ship_hdemo_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1210
      AND ws.ws_quantity > 1
      AND ws.ws_net_paid_inc_tax > 1000
      AND ws.ws_ship_hdemo_sk IN (25, 5834)
)
SELECT
    d.d_year,
    wp.wp_type,
    COUNT(DISTINCT wp.wp_url) AS unique_pages,
    SUM(s.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(s.ws_quantity) AS avg_quantity,
    MIN(s.ws_net_profit) AS min_profit,
    MAX(s.ws_net_profit) AS max_profit
FROM sold_sales s
JOIN web_page wp ON s.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
WHERE wp.wp_autogen_flag = 'N'
  AND wp.wp_char_count > 1000
  AND wp.wp_rec_start_date > DATE '2000-01-01'
  AND wp.wp_rec_end_date < DATE '2002-01-01'
  AND EXISTS (
        SELECT 1
        FROM date_dim d2
        WHERE wp.wp_creation_date_sk = d2.d_date_sk
          AND d2.d_weekend = 'Y'
          AND d2.d_year = 2000
    )
GROUP BY d.d_year, wp.wp_type
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
