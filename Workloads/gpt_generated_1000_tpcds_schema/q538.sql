WITH
  sampled_inventory AS (
    SELECT inv_item_sk,
           inv_date_sk,
           inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (5)  -- sample 5% of rows
    WHERE inv_quantity_on_hand > 0
  ),
  order_diff AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2000
    )
    EXCEPT
    SELECT ss_ticket_number
    FROM store_sales
    WHERE ss_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2000
    )
  )
SELECT
  d.d_year,
  s.s_state,
  i.i_category,
  CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_volume_flag,
  COUNT(DISTINCT cs.cs_order_number)                AS catalog_order_cnt,
  COUNT(DISTINCT ss.ss_ticket_number)               AS store_order_cnt,
  SUM(COALESCE(cs.cs_net_paid, 0)) + SUM(COALESCE(ss.ss_net_paid, 0)) AS total_net_paid,
  AVG(COALESCE(cs.cs_ext_discount_amt, 0) + COALESCE(ss.ss_ext_discount_amt, 0)) AS avg_discount,
  SUM(COALESCE(inv.inv_quantity_on_hand, 0))       AS total_inventory,
  MAX(p.p_cost) FILTER (WHERE p.p_discount_active = 'Y') AS max_active_promo_cost,
  SUM(promo_stats.promo_cnt)                       AS total_promo_cnt
FROM catalog_sales cs
FULL OUTER JOIN store_sales ss
  ON cs.cs_order_number = ss.ss_ticket_number
LEFT JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
     OR ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
     OR ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
     OR ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
     OR ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
     OR ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
     OR ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
     OR ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
     OR ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN sampled_inventory inv
  ON i.i_item_sk = inv.inv_item_sk
     AND d.d_date_sk = inv.inv_date_sk
FULL OUTER JOIN web_page wp
  ON c.c_customer_sk = wp.wp_customer_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS promo_cnt
  FROM promotion p2
  WHERE p2.p_item_sk = i.i_item_sk
) AS promo_stats ON TRUE
WHERE d.d_year = 2000
  AND ib.ib_lower_bound >= 120000
  AND s.s_manager = 'Ricky Nichols'
  AND (cs.cs_order_number IS NULL OR cs.cs_order_number IN (SELECT cs_order_number FROM order_diff))
GROUP BY CUBE (d.d_year, s.s_state, i.i_category)
ORDER BY d.d_year DESC, s.s_state, i.i_category
LIMIT 100
