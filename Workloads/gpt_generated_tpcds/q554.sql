WITH returns AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_item_sk,
    cr.cr_warehouse_sk,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_net_loss
  FROM catalog_returns cr
),
inventory_daily AS (
  SELECT
    inv.inv_date_sk,
    inv.inv_item_sk,
    inv.inv_warehouse_sk,
    inv.inv_quantity_on_hand
  FROM inventory inv
),
joined AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    w.w_state,
    i.i_category,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_return_quantity) AS total_return_quantity,
    SUM(r.cr_net_loss) AS total_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
  FROM returns r
  JOIN date_dim d ON r.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON r.cr_item_sk = i.i_item_sk
  JOIN warehouse w ON r.cr_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN inventory_daily inv
    ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = r.cr_item_sk
    AND inv.inv_warehouse_sk = r.cr_warehouse_sk
  WHERE d.d_date >= DATE '2020-01-01' AND d.d_date < DATE '2021-01-01'
  GROUP BY d.d_year, d.d_month_seq, w.w_state, i.i_category
)
SELECT
  d_year,
  d_month_seq,
  w_state,
  i_category,
  total_return_amount,
  total_return_quantity,
  total_net_loss,
  total_inventory_on_hand,
  CASE
    WHEN total_inventory_on_hand > 0 THEN total_return_quantity / total_inventory_on_hand
    ELSE NULL
  END AS return_quantity_ratio
FROM joined
ORDER BY d_year, d_month_seq, w_state, i_category
