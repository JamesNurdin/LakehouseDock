WITH sales_summary AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt
  FROM store_sales ss
  GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
)
SELECT
  d.d_date,
  i.i_product_name,
  cc.cc_name,
  sm.sm_type,
  promo.p_promo_name,
  COALESCE(ssum.total_net_paid, 0)          AS store_total_net_paid,
  COALESCE(cs.cs_net_paid, 0)               AS catalog_net_paid,
  CASE
    WHEN rs.r_reason_desc IS NOT NULL THEN 'Store Return'
    WHEN rw.r_reason_desc IS NOT NULL THEN 'Web Return'
    ELSE 'No Return'
  END                                         AS return_source,
  ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY COALESCE(ssum.total_net_paid, 0) DESC) AS rn_year
FROM sales_summary ssum
JOIN date_dim d
  ON ssum.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ssum.ss_item_sk = i.i_item_sk
LEFT JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
 AND ss.ss_item_sk = i.i_item_sk
LEFT JOIN customer cust
  ON ss.ss_customer_sk = cust.c_customer_sk
LEFT JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN promotion promo
  ON ss.ss_promo_sk = promo.p_promo_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d.d_date_sk
LEFT JOIN warehouse w
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
 AND cs.cs_item_sk = i.i_item_sk
LEFT JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason rs
  ON sr.sr_reason_sk = rs.r_reason_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN reason rw
  ON wr.wr_reason_sk = rw.r_reason_sk
LEFT JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#45'
  AND cc.cc_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND promo.p_cost > 500
  AND (rs.r_reason_desc LIKE '%product%' OR rw.r_reason_desc LIKE '%product%')
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_cost > 1000
      )
ORDER BY d.d_date, rn_year
LIMIT 100
