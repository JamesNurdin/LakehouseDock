WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS line_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
    GROUP BY ws.ws_order_number, ws.ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    sa.total_sales,
    sa.line_cnt,
    CASE WHEN ib.ib_upper_bound > 50000 THEN 'High' ELSE 'Low' END AS income_category,
    (SELECT SUM(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk) AS customer_total_returns,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY sa.total_sales DESC) AS rn_customer_sales,
    ROW_NUMBER() OVER (ORDER BY sa.total_sales DESC) AS global_rn
FROM sales_agg sa
JOIN customer c
  ON sa.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws2
  ON sa.ws_order_number = ws2.ws_order_number
JOIN ship_mode sm
  ON ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_inv
  ON ws2.ws_sold_date_sk = d_inv.d_date_sk
JOIN inventory inv
  ON d_inv.d_date_sk = inv.inv_date_sk
JOIN web_returns wr
  ON ws2.ws_order_number = wr.wr_order_number
WHERE hd.hd_vehicle_count > (SELECT MAX(hd3.hd_vehicle_count) FROM household_demographics hd3)
  AND sa.total_sales > (SELECT AVG(total_sales) FROM sales_agg)
ORDER BY sa.total_sales DESC
LIMIT 100
