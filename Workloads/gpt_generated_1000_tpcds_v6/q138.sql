WITH ws_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_sold_date_sk,
        ws_ship_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        AVG(ws_wholesale_cost) AS avg_wholesale_cost
    FROM web_sales
    WHERE ws_wholesale_cost > 20.00
      AND ws_coupon_amt < 2000.00
      AND ws_promo_sk IN (600, 318, 1193)
      AND ws_ext_sales_price > 100.00
      AND ws_ext_tax BETWEEN 5.00 AND 50.00
    GROUP BY ws_warehouse_sk, ws_sold_date_sk, ws_ship_date_sk
)
SELECT
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    w.w_warehouse_name,
    w.w_city,
    s.s_state,
    ws_agg.total_sales,
    ws_agg.total_profit,
    ws_agg.order_cnt,
    CASE WHEN ws_agg.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY ws_agg.total_sales DESC) AS sales_rank
FROM ws_agg
JOIN date_dim d_sold ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws_agg.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE w.w_gmt_offset = -6.00
  AND w.w_street_type = 'Avenue'
  AND s.s_state = 'CA'
  AND d_sold.d_month_seq BETWEEN 1200 AND 1220
  AND d_ship.d_month_seq BETWEEN 1200 AND 1220
GROUP BY
    d_sold.d_year,
    d_ship.d_year,
    w.w_warehouse_name,
    w.w_city,
    s.s_state,
    ws_agg.total_sales,
    ws_agg.total_profit,
    ws_agg.order_cnt
HAVING ws_agg.total_sales > 50000
ORDER BY ws_agg.total_sales DESC, profit_flag
LIMIT 100
