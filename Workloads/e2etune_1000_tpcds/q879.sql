WITH agg AS (
  SELECT
    s.s_store_name AS store_name,
    s.s_city AS city,
    s.s_state AS state,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COALESCE(SUM(wr.wr_net_loss), 0) AS web_net_loss,
    SUM(cr.cr_return_amt_inc_tax) + COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_return_amount_inc_tax,
    COUNT(DISTINCT cr.cr_order_number) AS total_orders
  FROM catalog_returns cr
  LEFT JOIN web_returns wr
    ON cr.cr_order_number = wr.wr_order_number
    AND cr.cr_item_sk = wr.wr_item_sk
  JOIN store s
    ON s.s_store_sk = cr.cr_warehouse_sk
  WHERE cr.cr_return_ship_cost > 0
    AND cr.cr_reason_sk IN (9, 16, 17, 59, 65)
  GROUP BY s.s_store_name, s.s_city, s.s_state
  HAVING (SUM(cr.cr_net_loss) + COALESCE(SUM(wr.wr_net_loss), 0)) > 5000
)
SELECT
  store_name,
  city,
  state,
  catalog_net_loss,
  web_net_loss,
  total_return_amount_inc_tax,
  total_orders,
  RANK() OVER (ORDER BY (catalog_net_loss + web_net_loss) DESC) AS loss_rank
FROM agg
ORDER BY loss_rank
LIMIT 10
