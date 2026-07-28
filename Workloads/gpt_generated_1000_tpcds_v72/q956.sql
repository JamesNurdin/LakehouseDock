WITH joined_data AS (
  SELECT
    cs.cs_net_paid_inc_tax,
    cs.cs_ext_discount_amt,
    cs.cs_bill_customer_sk,
    ss.ss_net_paid,
    wr.wr_return_amt,
    w.w_warehouse_name,
    w.w_state,
    s.s_store_name,
    s.s_state,
    p.p_promo_id,
    p.p_discount_active,
    t.t_meal_time,
    t.t_shift,
    wp.wp_type,
    inv.inv_quantity_on_hand
  FROM catalog_sales cs
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
   AND ss.ss_customer_sk = c_bill.c_customer_sk
   AND ss.ss_promo_sk = p.p_promo_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_refunded_customer_sk = c_bill.c_customer_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
   AND wp.wp_customer_sk = c_bill.c_customer_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE p.p_channel_catalog = 'N'
    AND p.p_purpose = 'Unknown'
    AND p.p_item_sk IN (75314, 2044)
    AND t.t_meal_time = 'dinner'
    AND t.t_shift = 'first'
    AND w.w_state = 'CA'
    AND s.s_state = 'TX'
    AND wp.wp_type = 'Home'
)
SELECT
  w_warehouse_name,
  s_store_name,
  p_promo_id,
  t_meal_time,
  SUM(cs_net_paid_inc_tax) AS total_catalog_sales,
  SUM(ss_net_paid) AS total_store_sales,
  SUM(wr_return_amt) AS total_return_amount,
  COUNT(DISTINCT cs_bill_customer_sk) AS distinct_customers,
  AVG(CASE WHEN p_discount_active = 'Y' THEN cs_ext_discount_amt ELSE 0 END) AS avg_discount_when_active
FROM joined_data
GROUP BY
  w_warehouse_name,
  s_store_name,
  p_promo_id,
  t_meal_time
HAVING SUM(cs_net_paid_inc_tax) > 10000
ORDER BY total_catalog_sales DESC
LIMIT 100
