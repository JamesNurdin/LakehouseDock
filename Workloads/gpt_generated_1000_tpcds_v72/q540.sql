WITH sales_agg AS (
  SELECT
    i.i_item_id AS item_id,
    i.i_brand AS brand,
    d.d_year AS year,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    (SELECT MAX(ib2.ib_upper_bound) FROM tpcds.income_band ib2) AS max_income_upper
  FROM tpcds.date_dim d
  JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
  JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_order_number = cs.cs_order_number
  JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d.d_date_sk
  JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
  JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_item_sk = i.i_item_sk
    AND sr.sr_customer_sk = c.c_customer_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_hdemo_sk = hd.hd_demo_sk
    AND sr.sr_store_sk = s.s_store_sk
  JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN tpcds.time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    AND wp.wp_creation_date_sk = d.d_date_sk
  JOIN tpcds.web_site wsit ON wsit.web_open_date_sk = d.d_date_sk
  JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_item_sk = i.i_item_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_web_page_sk = wp.wp_web_page_sk
    AND ws.ws_web_site_sk = wsit.web_site_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_promo_sk = p.p_promo_sk
  JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = i.i_item_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wr.wr_reason_sk = r.r_reason_sk
    AND wr.wr_order_number = ws.ws_order_number
    AND wr.wr_returned_time_sk = t.t_time_sk
  WHERE d.d_year = 2001
    AND cp.cp_department = 'Sports'
    AND i.i_brand = 'Brand#12'
    AND p.p_discount_active = 'Y'
    AND ib.ib_upper_bound > 100000
    AND sr.sr_fee > 30
    AND cs.cs_quantity > 5
    AND ws.ws_net_paid > 0
  GROUP BY i.i_item_id, i.i_brand, d.d_year
)
SELECT
  item_id,
  brand,
  year,
  total_profit,
  total_return_amount,
  total_store_return,
  total_web_profit,
  order_cnt,
  max_income_upper
FROM sales_agg
WHERE total_profit > 1000
  AND total_web_profit > 500
  AND EXISTS (
    SELECT 1
    FROM tpcds.web_returns wr2
    JOIN tpcds.item i2 ON wr2.wr_item_sk = i2.i_item_sk
    WHERE i2.i_item_id = sales_agg.item_id
      AND wr2.wr_return_amt > 0
  )
ORDER BY total_profit DESC
LIMIT 100
