/* goal: Analyze customer return performance by web site state and promotion activity, showing subtotals, grand total, ranking, and tax category while demonstrating advanced SQL features */
WITH base AS (
   SELECT
      sr.sr_returned_date_sk,
      sr.sr_customer_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      d.d_date,
      d.d_year,
      c.c_customer_id,
      c.c_preferred_cust_flag,
      p.p_promo_id,
      p.p_discount_active,
      cp.cp_catalog_page_id,
      cp.cp_type,
      i.inv_quantity_on_hand,
      i.inv_warehouse_sk,
      w.web_site_id,
      w.web_state,
      w.web_tax_percentage
   FROM store_returns sr
   JOIN date_dim d
     ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer c
     ON sr.sr_customer_sk = c.c_customer_sk
   JOIN promotion p
     ON p.p_start_date_sk = d.d_date_sk
   JOIN catalog_page cp
     ON cp.cp_start_date_sk = d.d_date_sk
   JOIN inventory i
     ON i.inv_date_sk = d.d_date_sk
   JOIN web_site w
     ON w.web_open_date_sk = d.d_date_sk
   WHERE d.d_year = 2001                         -- predicate 1
     AND w.web_tax_percentage > 0.05            -- predicate 2
     AND p.p_discount_active = 'Y'              -- predicate 3
     AND i.inv_warehouse_sk IN (12, 15, 17)      -- predicate 4
     AND cp.cp_type = 'Catalog'                 -- predicate 5
),
base_with_lateral AS (
   SELECT
      b.*,
      lr.total_return_all_time
   FROM base b
   CROSS JOIN LATERAL (
      SELECT SUM(sr2.sr_return_amt) AS total_return_all_time
      FROM store_returns sr2
      WHERE sr2.sr_customer_sk = b.sr_customer_sk
   ) AS lr
),
agg AS (
   SELECT
      b.c_customer_id,
      b.web_state,
      b.p_discount_active,
      CASE WHEN b.web_tax_percentage > 0.07 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
      SUM(b.sr_return_amt)                AS total_return_amt,
      SUM(b.sr_net_loss)                  AS total_net_loss,
      MAX(b.inv_quantity_on_hand)         AS max_quantity_on_hand,
      MAX(b.inv_warehouse_sk)             AS warehouse_sk,
      MAX(b.total_return_all_time)        AS total_return_all_time,
      (SELECT MAX(p_cost) FROM promotion) AS max_promo_cost
   FROM base_with_lateral b
   GROUP BY
      b.c_customer_id,
      b.web_state,
      b.p_discount_active,
      b.web_tax_percentage
),
rollup_totals AS (
   SELECT
      web_state,
      p_discount_active,
      SUM(total_return_amt)                         AS subtotal,
      SUM(SUM(total_return_amt)) OVER ()            AS grand_total
   FROM agg
   GROUP BY ROLLUP (web_state, p_discount_active)
)
SELECT
   a.c_customer_id,
   a.web_state,
   a.p_discount_active,
   a.tax_category,
   a.total_return_amt,
   a.total_net_loss,
   a.max_quantity_on_hand,
   a.warehouse_sk,
   CASE WHEN a.total_return_amt > a.max_promo_cost THEN 'AboveMaxCost' ELSE 'BelowOrEqual' END AS return_vs_max_cost,
   ROW_NUMBER() OVER (PARTITION BY a.web_state ORDER BY a.total_return_amt DESC) AS rn_state,
   rt.subtotal,
   rt.grand_total,
   mult.multiplier
FROM agg a
CROSS JOIN (VALUES ROW(1), ROW(2)) AS mult(multiplier)   -- small computed set
LEFT JOIN rollup_totals rt
  ON (rt.web_state = a.web_state AND rt.p_discount_active = a.p_discount_active)
WHERE EXISTS (
   SELECT 1 FROM inventory i
   WHERE i.inv_warehouse_sk = a.warehouse_sk
     AND i.inv_quantity_on_hand > 0
)
LIMIT 100
