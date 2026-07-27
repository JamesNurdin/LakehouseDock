WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND c.c_current_cdemo_sk IN (213219, 1196373)
      AND wp.wp_type = 'content'
      AND wp.wp_char_count BETWEEN 1000 AND 5000
      AND ws.ws_quantity >= 1
      AND ws.ws_net_profit > 0
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    d_year,
    total_profit,
    total_quantity,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
    CASE WHEN total_profit > 10000 THEN 'HIGH' ELSE 'MEDIUM' END AS profit_category
FROM sales_agg
ORDER BY d_year, profit_rank
LIMIT 100
