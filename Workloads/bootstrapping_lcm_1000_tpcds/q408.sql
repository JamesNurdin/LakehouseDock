SELECT
  s_store_id,
  d_year,
  num_returns,
  total_net_loss,
  avg_inventory_on_hand,
  youngest_birth_year,
  oldest_birth_year,
  total_return_amount_inc_tax,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS rank_in_year
FROM (
  SELECT
    s.s_store_id,
    d.d_year,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    MIN(c.c_birth_year) AS youngest_birth_year,
    MAX(c.c_birth_year) AS oldest_birth_year,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amount_inc_tax
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2005
  GROUP BY s.s_store_id, d.d_year
) t
ORDER BY total_net_loss DESC
LIMIT 100
