WITH base AS (
   SELECT
      cr.cr_returned_date_sk,
      cr.cr_ship_mode_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_store_credit,
      cr.cr_return_ship_cost,
      d.d_year,
      d.d_month_seq,
      sm.sm_code
   FROM catalog_returns cr
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   LEFT OUTER JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE
      cr.cr_return_amount > 0
      AND cr.cr_return_quantity BETWEEN 1 AND 10
      AND cr.cr_store_credit < 2000
      AND d.d_year BETWEEN 1999 AND 2002
      AND d.d_month_seq IN (1200, 1201, 1202)
      AND sm.sm_code IS NOT NULL
),
agg1 AS (
   SELECT
      d_year,
      sm_code,
      COUNT(*) AS cnt_returns,
      SUM(cr_return_amount) AS total_return_amount,
      AVG(cr_return_amount) AS avg_return_amount
   FROM base
   GROUP BY d_year, sm_code
),
top_groups AS (
   SELECT
      d_year,
      sm_code,
      total_return_amount
   FROM agg1
   WHERE total_return_amount > 5000
)
SELECT
   u.d_year,
   COUNT(*) AS cnt_modes,
   AVG(u.total_return_amount) AS avg_total_return_amount
FROM (
   SELECT d_year, sm_code, total_return_amount
   FROM top_groups
   WHERE sm_code = 'AIR'
   UNION ALL
   SELECT d_year, sm_code, total_return_amount
   FROM top_groups
   WHERE sm_code = 'SEA'
) u
GROUP BY u.d_year
ORDER BY u.d_year
LIMIT 100
