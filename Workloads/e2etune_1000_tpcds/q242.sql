WITH inv_agg AS (
  SELECT inv.inv_warehouse_sk,
         SUM(inv.inv_quantity_on_hand) AS total_qty,
         COUNT(*) AS inv_count
  FROM inventory inv
  WHERE inv.inv_quantity_on_hand > 500
  GROUP BY inv.inv_warehouse_sk
),
returns_agg AS (
  SELECT t.t_hour,
         SUM(wr.wr_net_loss) AS total_net_loss,
         COUNT(*) AS returns_count
  FROM web_returns wr
  JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
  WHERE t.t_hour BETWEEN 8 AND 18
  GROUP BY t.t_hour
),
air_ship_modes AS (
  SELECT sm_ship_mode_id, sm_type, sm_carrier
  FROM ship_mode
  WHERE sm_code = 'AIR'
)
SELECT
  w.w_warehouse_name,
  w.w_state,
  w.w_gmt_offset,
  i.total_qty,
  i.inv_count,
  r.t_hour,
  r.total_net_loss,
  r.returns_count,
  s.sm_type,
  s.sm_carrier
FROM inv_agg i
JOIN warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN returns_agg r
  ON 1 = 1
JOIN air_ship_modes s
  ON 1 = 1
WHERE w.w_gmt_offset BETWEEN -5 AND 5
ORDER BY i.total_qty DESC, r.total_net_loss DESC
LIMIT 100
