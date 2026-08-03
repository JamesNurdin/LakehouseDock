/*
  Goal: Analyse the average net loss of catalog returns per warehouse, together with the total inventory on hand and web sales profit, while filtering on specific demographic, shipping and geographic criteria. The query joins all 11 selected tables, pre‑aggregates inventory, applies multiple filters, uses a scalar sub‑query comparison, samples catalog_returns, and limits the result.
*/
WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    inv.total_on_hand,
    COUNT(DISTINCT cr.cr_order_number)                         AS return_order_cnt,
    SUM(cr.cr_net_loss)                                         AS total_net_loss,
    AVG(cr.cr_net_loss)                                         AS avg_net_loss,
    SUM(ws.ws_net_profit)                                       AS total_web_profit
FROM (
        SELECT *
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)
    ) cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
JOIN customer_address ca_ref
  ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
  ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
  ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN inv_agg inv
  ON w.w_warehouse_sk = inv.inv_warehouse_sk
JOIN web_sales ws
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN customer_address ca_wr_ref
  ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
JOIN household_demographics hd_wr_ref
  ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
JOIN income_band ib
  ON hd_wr_ref.hd_income_band_sk = ib.ib_income_band_sk
WHERE ca_ref.ca_state = 'TX'
  AND ib.ib_upper_bound > 50000
  AND sm.sm_carrier = 'AIRBORNE'
  AND cr.cr_return_quantity >= 5
  AND ws.ws_quantity <= 10
  AND cr.cr_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
      )
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    inv.total_on_hand
HAVING AVG(cr.cr_net_loss) > 0
ORDER BY avg_net_loss DESC
LIMIT 100
