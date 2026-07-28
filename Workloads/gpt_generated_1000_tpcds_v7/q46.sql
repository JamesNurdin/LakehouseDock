WITH sales_base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    p.p_promo_name,
    ib_bill.ib_lower_bound AS bill_income_lower,
    ib_ship.ib_upper_bound AS ship_income_upper,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS qty_sold
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
  JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN income_band ib_ship ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
  WHERE d_sold.d_year BETWEEN 1998 AND 2000
    AND sm.sm_type = 'OVERNIGHT'
    AND p.p_discount_active = 'N'
  GROUP BY
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    d_sold.d_year,
    d_ship.d_year,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    p.p_promo_name,
    ib_bill.ib_lower_bound,
    ib_ship.ib_upper_bound
)
SELECT
  sb.sold_year,
  sb.cc_name,
  sb.cp_department,
  SUM(sb.total_sales) AS year_total_sales,
  AVG(sb.total_profit) AS avg_profit_per_order,
  COUNT(DISTINCT sb.cs_order_number) AS distinct_orders,
  COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
  COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM sales_base sb
LEFT JOIN store_returns sr
  ON sr.sr_returned_date_sk = sb.cs_sold_date_sk
LEFT JOIN household_demographics hd_sr
  ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN income_band ib_sr
  ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_date_sk = sb.cs_sold_date_sk
LEFT JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_order_number = sb.cs_order_number
      AND wr2.wr_return_amt > 0
  )
  AND sb.bill_income_lower > 20000
  AND ib_sr.ib_upper_bound IS NOT NULL
GROUP BY
  sb.sold_year,
  sb.cc_name,
  sb.cp_department
HAVING SUM(sb.total_sales) > 100000
ORDER BY year_total_sales DESC
LIMIT 100
