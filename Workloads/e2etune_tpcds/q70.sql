WITH returns_agg AS (
  SELECT
    r.r_reason_desc AS reason_desc,
    p.p_promo_name AS promo_name,
    i.inv_warehouse_sk AS warehouse_sk,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(i.inv_quantity_on_hand) AS avg_on_hand,
    SUM(p.p_cost) AS total_promo_cost
  FROM web_returns wr
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  JOIN inventory i
    ON wr.wr_item_sk = i.inv_item_sk
  JOIN promotion p
    ON i.inv_item_sk = p.p_item_sk
  WHERE i.inv_date_sk BETWEEN 2450900 AND 2451100
    AND p.p_cost > 10
    AND r.r_reason_desc IS NOT NULL
  GROUP BY r.r_reason_desc, p.p_promo_name, i.inv_warehouse_sk
  HAVING SUM(wr.wr_return_amt) > 500
)
SELECT
  reason_desc,
  promo_name,
  warehouse_sk,
  total_return_amt,
  total_return_qty,
  total_net_loss,
  avg_on_hand,
  total_promo_cost,
  RANK() OVER (PARTITION BY reason_desc ORDER BY total_return_amt DESC) AS promo_rank_by_reason
FROM returns_agg
ORDER BY total_return_amt DESC
LIMIT 100
