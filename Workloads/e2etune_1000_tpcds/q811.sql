WITH store_agg AS (
  SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    r.r_reason_desc,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(sr.sr_return_amt_inc_tax) AS store_return_amt_inc_tax
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND i.i_current_price > 20
  GROUP BY d.d_year, d.d_moy, i.i_category, r.r_reason_desc
),
web_agg AS (
  SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    r.r_reason_desc,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(wr.wr_return_amt_inc_tax) AS web_return_amt_inc_tax
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND i.i_current_price > 20
  GROUP BY d.d_year, d.d_moy, i.i_category, r.r_reason_desc
),
inventory_agg AS (
  SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
  FROM inventory inv
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  JOIN item i ON inv.inv_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND i.i_current_price > 20
  GROUP BY d.d_year, d.d_moy, i.i_category
)
SELECT
  COALESCE(s.d_year, w.d_year) AS year,
  COALESCE(s.d_moy, w.d_moy) AS month,
  COALESCE(s.i_category, w.i_category) AS category,
  COALESCE(s.r_reason_desc, w.r_reason_desc) AS reason,
  COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
  COALESCE(s.store_return_amt_inc_tax, 0) + COALESCE(w.web_return_amt_inc_tax, 0) AS total_return_amount_inc_tax,
  i.avg_inventory_qty
FROM store_agg s
FULL OUTER JOIN web_agg w
  ON s.d_year = w.d_year
  AND s.d_moy = w.d_moy
  AND s.i_category = w.i_category
  AND s.r_reason_desc = w.r_reason_desc
LEFT JOIN inventory_agg i
  ON i.d_year = COALESCE(s.d_year, w.d_year)
  AND i.d_moy = COALESCE(s.d_moy, w.d_moy)
  AND i.i_category = COALESCE(s.i_category, w.i_category)
ORDER BY year, month, category, total_net_loss DESC
LIMIT 100
