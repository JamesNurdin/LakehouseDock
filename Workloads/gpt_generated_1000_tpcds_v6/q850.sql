WITH base AS (
  SELECT
    d.d_year,
    sm.sm_ship_mode_id,
    sm.sm_type,
    hd.hd_buy_potential,
    CASE WHEN hd.hd_dep_count >= 5 THEN 'Large' ELSE 'Small' END AS household_category,
    cr.cr_net_loss,
    sr.sr_net_loss,
    cr.cr_return_quantity,
    cr.cr_return_amount
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
  LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
  LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
),
agg1 AS (
  SELECT
    d_year,
    sm_ship_mode_id,
    sm_type,
    hd_buy_potential,
    household_category,
    SUM(cr_net_loss) AS sum_catalog_loss,
    SUM(sr_net_loss) AS sum_store_loss,
    COUNT(*) AS txn_count,
    (SUM(cr_net_loss) + SUM(sr_net_loss)) / NULLIF(COUNT(*), 0) AS avg_loss_per_txn
  FROM base
  WHERE d_year BETWEEN 2000 AND 2002
    AND cr_return_quantity > 1
    AND cr_return_amount > 100
  GROUP BY d_year, sm_ship_mode_id, sm_type, hd_buy_potential, household_category
),
agg2 AS (
  SELECT
    d_year,
    SUM(sum_catalog_loss + sum_store_loss) AS year_total_loss,
    SUM(txn_count) AS year_txn_count
  FROM agg1
  GROUP BY d_year
)
SELECT
  a.d_year,
  a.sm_ship_mode_id,
  a.sm_type,
  a.hd_buy_potential,
  a.household_category,
  a.sum_catalog_loss,
  a.sum_store_loss,
  a.txn_count,
  a.avg_loss_per_txn,
  b.year_total_loss,
  b.year_txn_count,
  b.year_total_loss / NULLIF(b.year_txn_count, 0) AS avg_year_loss_per_txn
FROM agg1 a
JOIN agg2 b ON a.d_year = b.d_year
WHERE (a.sum_catalog_loss + a.sum_store_loss) > 500
ORDER BY a.avg_loss_per_txn DESC
LIMIT 100
