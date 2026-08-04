WITH base AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_net_paid,
    cs.cs_ext_discount_amt,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    cr.cr_return_amount,
    c.c_customer_id,
    i.i_brand,
    i.i_category_id,
    s.s_store_name,
    s.s_floor_space,
    p.p_promo_name,
    cc.cc_call_center_id,
    w.w_warehouse_name,
    t1.t_hour,
    t1.t_sub_shift,
    CASE WHEN sr.sr_return_quantity > 5 THEN 'Large' ELSE 'Small' END AS return_size_category,
    u.flag
  FROM store_sales ss
  JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  CROSS JOIN UNNEST(ARRAY['Flag1','Flag2']) AS u(flag)
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = i.i_item_sk
  JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
  WHERE s.s_floor_space > 8000000
    AND i.i_category_id = 4
    AND t1.t_sub_shift = 'morning'
)
SELECT
  s_store_name,
  i_brand,
  t_hour,
  return_size_category,
  flag,
  COUNT(DISTINCT c_customer_id) AS unique_customers,
  SUM(ss_net_paid) AS total_net_paid,
  AVG(cs_ext_discount_amt) AS avg_discount,
  MIN(cr_return_amount) AS min_return_amount,
  MAX(sr_return_amt) AS max_return_amount
FROM base
GROUP BY
  s_store_name,
  i_brand,
  t_hour,
  return_size_category,
  flag
ORDER BY total_net_paid DESC
LIMIT 100
