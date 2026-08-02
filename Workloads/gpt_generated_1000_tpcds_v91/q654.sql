WITH
  cs_agg AS (
    SELECT
      cs.cs_order_number,
      SUM(cs.cs_net_paid) AS cs_total_net_paid,
      SUM(cs.cs_ext_sales_price) AS cs_total_ext_sales_price,
      MIN(cs.cs_sold_date_sk) AS cs_min_sold_date_sk,
      MAX(cs.cs_sold_date_sk) AS cs_max_sold_date_sk,
      MIN(cs.cs_sold_time_sk) AS cs_min_sold_time_sk,
      MAX(cs.cs_sold_time_sk) AS cs_max_sold_time_sk,
      MAX(cs.cs_bill_customer_sk) AS cs_bill_customer_sk,
      MAX(cs.cs_promo_sk) AS cs_promo_sk,
      MAX(cs.cs_catalog_page_sk) AS cs_catalog_page_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_paid > 0
    GROUP BY cs.cs_order_number
  ),
  intersect_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
    INTERSECT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
  )
SELECT
  d.d_date AS sale_date,
  cu.c_customer_id,
  cu.c_first_name,
  cu.c_last_name,
  cd.cd_education_status,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  cp.cp_description,
  p.p_promo_name,
  r.r_reason_desc,
  ca.cs_total_net_paid,
  ss.ss_net_paid,
  ws.ws_net_paid,
  cr.cr_net_loss,
  (ca.cs_total_net_paid + ss.ss_net_paid + ws.ws_net_paid - cr.cr_net_loss) AS total_net_profit,
  CASE
    WHEN (ca.cs_total_net_paid + ss.ss_net_paid + ws.ws_net_paid - cr.cr_net_loss) > 10000 THEN 'HIGH'
    ELSE 'NORMAL'
  END AS profit_category,
  RANK() OVER (PARTITION BY d.d_year ORDER BY (ca.cs_total_net_paid + ss.ss_net_paid + ws.ws_net_paid - cr.cr_net_loss) DESC) AS profit_rank,
  top_item.cs_item_sk AS top_item_sk,
  top_item.cs_quantity AS top_item_quantity,
  (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS total_active_promotions
FROM cs_agg ca
JOIN intersect_orders io ON ca.cs_order_number = io.cs_order_number
JOIN catalog_page cp ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON ca.cs_promo_sk = p.p_promo_sk
JOIN date_dim d ON ca.cs_min_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ca.cs_min_sold_time_sk = t.t_time_sk
JOIN customer cu ON ca.cs_bill_customer_sk = cu.c_customer_sk
JOIN customer_address ca_addr ON cu.c_current_addr_sk = ca_addr.ca_address_sk
JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cu.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss ON ss.ss_customer_sk = cu.c_customer_sk
  AND ss.ss_sold_date_sk = d.d_date_sk
  AND ss.ss_sold_time_sk = t.t_time_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = cu.c_customer_sk
  AND ws.ws_sold_date_sk = d.d_date_sk
  AND ws.ws_sold_time_sk = t.t_time_sk
JOIN catalog_returns cr ON cr.cr_order_number = ca.cs_order_number
  AND cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_returned_time_sk = t.t_time_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
CROSS JOIN LATERAL (
  SELECT cs.cs_item_sk, cs.cs_quantity
  FROM catalog_sales cs
  WHERE cs.cs_order_number = ca.cs_order_number
  ORDER BY cs.cs_quantity DESC
  LIMIT 1
) AS top_item
WHERE d.d_year = 2001
  AND cd.cd_education_status IN ('College', 'Advanced Degree')
  AND p.p_discount_active = 'Y'
  AND hd.hd_buy_potential = 'High'
  AND cr.cr_net_loss > 0
  AND t.t_hour BETWEEN 9 AND 17
  AND ca.cs_total_net_paid > 1000
ORDER BY profit_rank, d.d_date, cu.c_customer_id
LIMIT 100
