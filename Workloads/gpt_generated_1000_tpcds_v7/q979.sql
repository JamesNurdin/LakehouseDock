WITH joined AS (
  SELECT
    cr.cr_return_amount,
    cr.cr_net_loss,
    d.d_year,
    d.d_month_seq,
    sm.sm_ship_mode_id,
    sm.sm_code,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    inv.inv_quantity_on_hand,
    s.s_store_id,
    s.s_floor_space
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
    AND sm.sm_code IN ('AIR', 'SEA')
    AND cr.cr_return_amount > 100
    AND inv.inv_quantity_on_hand BETWEEN 500 AND 800
    AND s.s_floor_space > 8000000
),
agg AS (
  SELECT
    s_store_id AS store_id,
    sm_ship_mode_id AS ship_mode_id,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    SUM(inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(*) AS txn_count
  FROM joined
  GROUP BY s_store_id, sm_ship_mode_id
)
SELECT
  x.store_id,
  x.ship_mode_id,
  x.total_return_amount,
  x.total_sales,
  x.total_profit,
  x.total_inventory_qty,
  x.txn_count,
  x.profit_margin,
  x.avg_return_per_txn
FROM (
  SELECT
    store_id,
    ship_mode_id,
    total_return_amount,
    total_sales,
    total_profit,
    total_inventory_qty,
    txn_count,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    total_return_amount / NULLIF(txn_count, 0) AS avg_return_per_txn
  FROM agg
) x
WHERE x.total_sales > 100000
  AND x.profit_margin > 0.05
  AND x.avg_return_per_txn > 50
ORDER BY x.profit_margin DESC
LIMIT 20
