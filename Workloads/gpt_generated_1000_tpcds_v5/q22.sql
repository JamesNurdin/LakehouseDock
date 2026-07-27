WITH catalog_loss AS (
  SELECT
    c.c_customer_id AS customer_id,
    'Catalog' AS loss_type,
    SUM(cr.cr_net_loss) AS net_loss,
    CASE WHEN SUM(cr.cr_net_loss) > 100 THEN 'High' ELSE 'Low' END AS loss_category
  FROM catalog_returns cr
  JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc = 'Parts missing'
  GROUP BY c.c_customer_id
),
web_loss AS (
  SELECT
    c.c_customer_id AS customer_id,
    'Web' AS loss_type,
    SUM(wr.wr_net_loss) AS net_loss,
    CASE WHEN SUM(wr.wr_net_loss) > 100 THEN 'High' ELSE 'Low' END AS loss_category
  FROM web_returns wr
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc = 'Parts missing'
  GROUP BY c.c_customer_id
),
combined AS (
  SELECT * FROM catalog_loss
  UNION ALL
  SELECT * FROM web_loss
),
ranked AS (
  SELECT
    customer_id,
    loss_type,
    net_loss,
    loss_category,
    ROW_NUMBER() OVER (PARTITION BY loss_type ORDER BY net_loss DESC) AS loss_rank
  FROM combined
)
SELECT
  customer_id,
  loss_type,
  net_loss,
  loss_category,
  loss_rank
FROM ranked
ORDER BY loss_type, loss_rank
LIMIT 100
