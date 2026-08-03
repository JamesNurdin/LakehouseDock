WITH
  sales AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      c.c_customer_id,
      ca.ca_country AS customer_country,
      d.d_year,
      i.i_category,
      p.p_promo_name,
      sm.sm_type AS ship_mode_type,
      w.w_warehouse_name,
      cc.cc_name AS call_center_name,
      cp.cp_department,
      t.t_hour,
      LAG(cs.cs_net_paid) OVER (PARTITION BY d.d_year ORDER BY cs.cs_order_number) AS lag_net_paid,
      SUM(cs.cs_net_paid) OVER (PARTITION BY d.d_year ORDER BY cs.cs_order_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid_year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  ),
  returns AS (
    SELECT
      cr.cr_order_number,
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_item_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_net_loss,
      c.c_customer_id AS refunded_customer_id,
      ca.ca_country AS refunded_country,
      d.d_year,
      i.i_category,
      p.p_promo_name,
      sm.sm_type AS ship_mode_type,
      w.w_warehouse_name,
      cc.cc_name AS call_center_name,
      cp.cp_department,
      t.t_hour
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN promotion p ON cr.cr_item_sk = p.p_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  ),
  store_ret AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_item_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      c.c_customer_id AS store_customer_id,
      ca.ca_country AS store_customer_country,
      d.d_year,
      i.i_category,
      s.s_store_name,
      t.t_hour
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
  ),
  combined_sales_returns AS (
    SELECT
      COALESCE(s.cs_order_number, r.cr_order_number) AS order_number,
      COALESCE(s.cs_item_sk, r.cr_item_sk) AS item_sk,
      COALESCE(s.d_year, r.d_year) AS year,
      s.cs_quantity,
      r.cr_return_quantity,
      s.cs_net_paid,
      r.cr_return_amount,
      s.cs_net_profit,
      r.cr_net_loss,
      s.customer_country,
      r.refunded_country,
      s.i_category,
      s.t_hour AS hour,
      CASE
        WHEN s.cs_quantity IS NULL THEN 'ReturnOnly'
        WHEN r.cr_return_quantity IS NULL THEN 'SaleOnly'
        ELSE 'SaleAndReturn'
      END AS trans_type,
      s.lag_net_paid,
      s.running_net_paid_year
    FROM sales s
    FULL OUTER JOIN returns r
      ON s.cs_item_sk = r.cr_item_sk
     AND s.cs_sold_date_sk = r.cr_returned_date_sk
  ),
  final_combined AS (
    SELECT
      COALESCE(cr.order_number, sr.sr_ticket_number) AS transaction_id,
      COALESCE(cr.item_sk, sr.sr_item_sk) AS item_sk,
      COALESCE(cr.year, sr.d_year) AS year,
      cr.cs_quantity,
      cr.cr_return_quantity,
      cr.cs_net_paid,
      cr.cr_return_amount,
      cr.cs_net_profit,
      cr.cr_net_loss,
      cr.customer_country,
      cr.refunded_country,
      sr.store_customer_country,
      cr.i_category,
      sr.s_store_name,
      cr.hour,
      cr.trans_type,
      cr.lag_net_paid,
      cr.running_net_paid_year
    FROM combined_sales_returns cr
    FULL OUTER JOIN store_ret sr
      ON cr.item_sk = sr.sr_item_sk
     AND cr.year = sr.d_year
  )
SELECT
  year,
  trans_type,
  s_store_name,
  SUM(cs_quantity) AS total_qty_sold,
  SUM(cr_return_quantity) AS total_qty_returned,
  SUM(cs_net_paid) AS total_net_paid,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(cs_net_profit) AS total_net_profit,
  SUM(cr_net_loss) AS total_net_loss,
  CASE
    WHEN SUM(cs_net_paid) - SUM(cr_return_amount) > 0 THEN 'PROFIT'
    ELSE 'LOSS'
  END AS overall_result,
  SUM(running_net_paid_year) AS sum_running_net_paid_year
FROM final_combined
WHERE
  year BETWEEN 1999 AND 2002
  AND (customer_country = 'United States' OR refunded_country = 'United States')
  AND store_customer_country = 'United States'
  AND i_category = 'Sports'
  AND hour BETWEEN 8 AND 18
GROUP BY ROLLUP (year, trans_type, s_store_name)
ORDER BY year, trans_type
LIMIT 100
