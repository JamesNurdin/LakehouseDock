WITH months AS (
  SELECT DISTINCT d_year, d_moy
  FROM date_dim
  WHERE d_year BETWEEN 2001 AND 2002
),
catalog_monthly AS (
  SELECT d.d_year,
         d.d_moy,
         cp.cp_department,
         SUM(cr.cr_net_loss) AS total_catalog_net_loss,
         SUM(cr.cr_return_amt_inc_tax) AS total_catalog_return_amt_inc_tax
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
    AND cp.cp_type = 'monthly'
  GROUP BY d.d_year, d.d_moy, cp.cp_department
),
store_monthly AS (
  SELECT d.d_year,
         d.d_moy,
         SUM(sr.sr_net_loss) AS total_store_net_loss,
         SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amt_inc_tax
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
  GROUP BY d.d_year, d.d_moy
),
web_monthly AS (
  SELECT d.d_year,
         d.d_moy,
         SUM(wr.wr_net_loss) AS total_web_net_loss,
         SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amt_inc_tax
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
  GROUP BY d.d_year, d.d_moy
),
inventory_monthly AS (
  SELECT d.d_year,
         d.d_moy,
         AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
  FROM inventory inv
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2001 AND 2002
  GROUP BY d.d_year, d.d_moy
)
SELECT m.d_year,
       m.d_moy,
       cm.cp_department,
       cm.total_catalog_net_loss,
       sm.total_store_net_loss,
       wm.total_web_net_loss,
       im.avg_inventory_qty,
       (COALESCE(cm.total_catalog_net_loss,0) + COALESCE(sm.total_store_net_loss,0) + COALESCE(wm.total_web_net_loss,0)) AS total_combined_net_loss
FROM months m
LEFT JOIN catalog_monthly cm ON m.d_year = cm.d_year AND m.d_moy = cm.d_moy
LEFT JOIN store_monthly sm ON m.d_year = sm.d_year AND m.d_moy = sm.d_moy
LEFT JOIN web_monthly wm ON m.d_year = wm.d_year AND m.d_moy = wm.d_moy
LEFT JOIN inventory_monthly im ON m.d_year = im.d_year AND m.d_moy = im.d_moy
WHERE cm.cp_department IS NOT NULL
ORDER BY total_combined_net_loss DESC
LIMIT 100
