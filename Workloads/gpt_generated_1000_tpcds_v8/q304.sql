WITH combined AS (
  -- Catalog returns aggregated per reason
  SELECT
    r.r_reason_sk,
    r.r_reason_id,
    r.r_reason_desc,
    'catalog' AS source,
    SUM(cr.cr_net_loss) AS loss_amount
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cr.cr_reason_sk IN (
    SELECT r2.r_reason_sk FROM reason r2 WHERE LOWER(r2.r_reason_desc) LIKE '%warranty%'
  )
  GROUP BY r.r_reason_sk, r.r_reason_id, r.r_reason_desc

  UNION ALL

  -- Web returns aggregated per reason
  SELECT
    r.r_reason_sk,
    r.r_reason_id,
    r.r_reason_desc,
    'web' AS source,
    SUM(wr.wr_net_loss) AS loss_amount
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_id IN (
    SELECT r2.r_reason_id FROM reason r2 WHERE LOWER(r2.r_reason_desc) LIKE '%working%'
  )
  GROUP BY r.r_reason_sk, r.r_reason_id, r.r_reason_desc
)
SELECT
  c.r_reason_id,
  c.r_reason_desc,
  c.source,
  SUM(c.loss_amount) AS total_loss,
  CASE WHEN SUM(c.loss_amount) > 10000 THEN 'High' ELSE 'Low' END AS loss_category,
  ROW_NUMBER() OVER (ORDER BY SUM(c.loss_amount) DESC) AS loss_rank,
  (
    SELECT SUM(cs.cs_quantity)
    FROM catalog_sales cs
    JOIN catalog_returns cr2 ON cs.cs_item_sk = cr2.cr_item_sk
    WHERE cr2.cr_reason_sk = c.r_reason_sk
  ) AS total_quantity_sold
FROM combined c
GROUP BY c.r_reason_sk, c.r_reason_id, c.r_reason_desc, c.source
HAVING SUM(c.loss_amount) > 5000
ORDER BY loss_rank
