WITH
  agg_returns AS (
    SELECT
      r.r_reason_id,
      r.r_reason_desc,
      SUM(cr.cr_return_amount) AS cat_return_amount,
      SUM(cr.cr_net_loss) AS cat_net_loss,
      SUM(wr.wr_return_amt) AS web_return_amount,
      SUM(wr.wr_net_loss) AS web_net_loss,
      COUNT(DISTINCT cr.cr_order_number) AS cat_order_cnt,
      COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returning_addr_sk BETWEEN 2000000 AND 5000000
      AND cr.cr_return_quantity > 1
      AND cr.cr_return_amount > 100
      AND wr.wr_returning_addr_sk IN (4135405, 4798793, 2670389)
      AND wr.wr_return_amt_inc_tax < 1500
    GROUP BY r.r_reason_id, r.r_reason_desc
  ),
  intersect_orders AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id = 'AAAAAAAALAAAAAAA'
    INTERSECT
    SELECT wr.wr_order_number
    FROM web_returns wr
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE r2.r_reason_id = 'AAAAAAAALAAAAAAA'
  ),
  filtered_agg AS (
    SELECT ar.*
    FROM agg_returns ar
    WHERE EXISTS (
      SELECT 1
      FROM catalog_returns cr
      JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
      WHERE cr.cr_order_number IN (SELECT order_number FROM intersect_orders)
        AND r.r_reason_id = ar.r_reason_id
    )
  )
SELECT
  fr.r_reason_id,
  fr.r_reason_desc,
  fr.cat_return_amount,
  fr.web_return_amount,
  CASE
    WHEN (fr.cat_return_amount + fr.web_return_amount) = 0 THEN NULL
    ELSE (fr.cat_net_loss + fr.web_net_loss) / (fr.cat_return_amount + fr.web_return_amount)
  END AS loss_rate,
  fr.cat_order_cnt,
  fr.web_order_cnt
FROM filtered_agg fr
WHERE fr.r_reason_id NOT IN (
  SELECT r.r_reason_id
  FROM reason r
  WHERE r.r_reason_desc LIKE '%size%'
)
ORDER BY loss_rate DESC NULLS LAST
LIMIT 100
