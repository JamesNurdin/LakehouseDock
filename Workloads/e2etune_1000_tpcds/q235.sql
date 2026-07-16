WITH returns_agg AS (
  SELECT
    ca_ret.ca_state AS state,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND cr.cr_return_amount > 50
  GROUP BY ca_ret.ca_state, d.d_year, d.d_month_seq
),
inventory_agg AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
  FROM inventory inv
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_month_seq
)
SELECT
  r.state,
  r.year,
  r.month_seq,
  r.total_return_amount,
  r.avg_return_tax,
  r.distinct_refunded_customers,
  i.total_inventory_qty,
  r.total_return_amount / NULLIF(i.total_inventory_qty, 0) AS return_to_inventory_ratio,
  RANK() OVER (PARTITION BY r.year ORDER BY r.total_return_amount DESC) AS state_rank
FROM returns_agg r
JOIN inventory_agg i
  ON r.year = i.year AND r.month_seq = i.month_seq
WHERE r.return_cnt >= 10
ORDER BY r.year, state_rank
LIMIT 100
