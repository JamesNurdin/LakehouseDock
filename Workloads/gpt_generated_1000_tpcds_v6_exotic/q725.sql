WITH sales_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_web_page_sk,
        SUM(ws_net_profit)           AS total_profit,
        SUM(ws_quantity)             AS total_qty,
        COUNT(DISTINCT ws_order_number) AS orders_cnt
    FROM web_sales
    WHERE ws_net_profit > 0
      AND ws_quantity >= 1
      AND ws_ext_sales_price > 100
      AND ws_ship_mode_sk IS NOT NULL
    GROUP BY ws_warehouse_sk, ws_sold_date_sk, ws_sold_time_sk, ws_web_page_sk
    HAVING SUM(ws_net_profit) > 5000
),
returns_by_date AS (
    SELECT DISTINCT wr_returned_date_sk
    FROM web_returns
    WHERE wr_return_amt > 0
)
SELECT
    d.d_date,
    d.d_year,
    w.w_warehouse_name,
    w.w_city,
    wp.wp_url,
    t.t_hour,
    sa.total_profit,
    sa.total_qty,
    sa.orders_cnt,
    RANK() OVER (PARTITION BY d.d_year ORDER BY sa.total_profit DESC) AS profit_rank,
    CASE
        WHEN sa.total_profit >= 20000 THEN 'High'
        WHEN sa.total_profit >= 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_tier
FROM sales_agg sa
JOIN date_dim d
    ON sa.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON sa.ws_sold_time_sk = t.t_time_sk
JOIN warehouse w
    ON sa.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON sa.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND w.w_state = 'CA'
  AND w.w_gmt_offset BETWEEN -5 AND 5
  AND wp.wp_type = 'Home'
  AND t.t_hour BETWEEN 9 AND 17
  AND NOT EXISTS (
        SELECT 1
        FROM returns_by_date r
        WHERE r.wr_returned_date_sk = sa.ws_sold_date_sk
    )
ORDER BY profit_rank, d.d_date
LIMIT 100
