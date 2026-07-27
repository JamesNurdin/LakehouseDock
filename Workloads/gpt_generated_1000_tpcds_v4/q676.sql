WITH joined_data AS (
  SELECT
    s.s_store_id,
    s.s_state,
    i.i_brand,
    i.i_current_price,
    p.p_channel_catalog,
    CASE WHEN p.p_channel_catalog = 'Y' THEN 'Catalog' ELSE 'Other' END AS promo_type,
    t_cs.t_hour AS cs_hour,
    cs.cs_net_paid,
    ss.ss_net_paid,
    cr.cr_return_amount,
    c_bill.c_customer_id,
    c_bill.c_birth_year,
    ib.ib_lower_bound
  FROM catalog_sales cs
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
  JOIN customer c_ss
    ON ss.ss_customer_sk = c_ss.c_customer_sk
  JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
  JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
  JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_page wp
    ON wp.wp_customer_sk = c_bill.c_customer_sk
  WHERE s.s_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND t_cs.t_hour BETWEEN 9 AND 17
    AND p.p_channel_catalog = 'Y'
    AND ib.ib_lower_bound >= 50000
    AND c_bill.c_birth_year BETWEEN 1970 AND 1990
)
SELECT
  s_store_id,
  i_brand,
  promo_type,
  SUM(cs_net_paid) AS total_catalog_sales,
  SUM(ss_net_paid) AS total_store_sales,
  SUM(cr_return_amount) AS total_return_amount,
  COUNT(DISTINCT c_customer_id) AS distinct_customers,
  AVG(i_current_price) AS avg_item_price,
  MIN(cs_net_paid) AS min_catalog_sale,
  MAX(cs_net_paid) AS max_catalog_sale
FROM joined_data
GROUP BY s_store_id, i_brand, promo_type
HAVING SUM(cs_net_paid) > 10000
   AND COUNT(DISTINCT c_customer_id) > 5
ORDER BY total_catalog_sales DESC
LIMIT 100
