WITH filtered AS (
  SELECT
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_purchase_estimate,
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    sm.sm_type,
    w.w_warehouse_name,
    w.w_city,
    s.s_store_name,
    s.s_floor_space,
    cr.cr_net_loss AS cr_net_loss,
    sr.sr_net_loss AS sr_net_loss,
    wr.wr_net_loss AS wr_net_loss,
    inv.inv_quantity_on_hand
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE cd.cd_purchase_estimate >= 8000
    AND cr.cr_return_tax > 20.0
    AND COALESCE(sr.sr_return_tax, 0) < 15.0
    AND sm.sm_type = 'AIR'
    AND COALESCE(s.s_floor_space, 0) > 6000000
    AND COALESCE(inv.inv_quantity_on_hand, 0) > 0
    AND w.w_gmt_offset BETWEEN -5 AND 5
)
SELECT
  s_store_name,
  cp_department,
  SUM(cr_net_loss) + SUM(sr_net_loss) + SUM(wr_net_loss) AS total_net_loss,
  AVG(cd_purchase_estimate) AS avg_purchase_estimate,
  CASE
    WHEN SUM(cr_net_loss) + SUM(sr_net_loss) + SUM(wr_net_loss) >
         (SELECT avg(cr_net_loss) FROM catalog_returns) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS loss_category,
  ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY SUM(cr_net_loss) + SUM(sr_net_loss) + SUM(wr_net_loss) DESC) AS loss_rank_within_dept
FROM filtered
GROUP BY GROUPING SETS (
  (s_store_name, cp_department),
  (s_store_name),
  (cp_department)
)
ORDER BY total_net_loss DESC
LIMIT 100
