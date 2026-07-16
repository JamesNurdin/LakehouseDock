WITH cr AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_call_center_sk,
    d.d_year,
    d.d_quarter_name,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    COUNT(*) AS cnt_returns
  FROM
    call_center cc
    JOIN catalog_returns cr ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE
    cc.cc_gmt_offset = -5.00
    AND d.d_year = 2002
    AND cc.cc_state = 'CA'
  GROUP BY
    cc.cc_call_center_id,
    cc.cc_call_center_sk,
    d.d_year,
    d.d_quarter_name
),
inv AS (
  SELECT
    d.d_year,
    d.d_quarter_name,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
  FROM
    inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  WHERE
    d.d_year = 2002
  GROUP BY
    d.d_year,
    d.d_quarter_name
)
SELECT
  cr.cc_call_center_id,
  cr.d_year,
  cr.d_quarter_name,
  cr.total_net_loss,
  cr.total_return_amount,
  cr.total_return_qty,
  cr.cnt_returns,
  inv.avg_inventory_qty,
  ROUND(cr.total_net_loss / NULLIF(inv.avg_inventory_qty, 0), 2) AS loss_per_inventory,
  RANK() OVER (PARTITION BY cr.d_year ORDER BY cr.total_net_loss DESC) AS loss_rank
FROM
  cr
  JOIN inv ON cr.d_year = inv.d_year AND cr.d_quarter_name = inv.d_quarter_name
ORDER BY
  cr.d_year,
  loss_rank
LIMIT 100
