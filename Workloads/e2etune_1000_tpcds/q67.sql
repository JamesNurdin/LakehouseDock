WITH inv_agg AS (
  SELECT
    it.i_category,
    w.w_warehouse_name,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty
  FROM inventory i
  JOIN item it ON i.inv_item_sk = it.i_item_sk
  JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE i.inv_quantity_on_hand > 200
  GROUP BY it.i_category, w.w_warehouse_name
),
ret_agg AS (
  SELECT
    it.i_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amt
  FROM store_returns sr
  JOIN item it ON sr.sr_item_sk = it.i_item_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE sr.sr_return_quantity > 0
    AND sr.sr_return_amt > 0
  GROUP BY it.i_category
)
SELECT
  i.i_category,
  i.w_warehouse_name,
  i.total_inventory_qty,
  COALESCE(r.total_return_qty, 0) AS total_return_qty,
  COALESCE(r.total_net_loss, 0) AS total_net_loss,
  CASE WHEN i.total_inventory_qty > 0 THEN
    COALESCE(r.total_return_qty, 0) * 1.0 / i.total_inventory_qty
  ELSE NULL END AS return_rate,
  RANK() OVER (ORDER BY COALESCE(r.total_net_loss, 0) DESC) AS net_loss_rank
FROM inv_agg i
LEFT JOIN ret_agg r ON i.i_category = r.i_category
ORDER BY net_loss_rank
LIMIT 50
