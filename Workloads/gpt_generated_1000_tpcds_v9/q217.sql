WITH
sales AS (
  SELECT
    'sales' AS metric_type,
    sm.sm_carrier AS carrier,
    sum(cs.cs_net_paid_inc_ship) AS total_amount,
    (
      SELECT avg(cs2.cs_net_paid_inc_ship)
      FROM catalog_sales cs2
      JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
      WHERE d2.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    ) AS avg_net_paid_all_carriers
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND sm.sm_carrier IN (
      SELECT sm2.sm_carrier
      FROM ship_mode sm2
      WHERE sm2.sm_carrier IN ('MSC', 'LATVIAN')
    )
  GROUP BY sm.sm_carrier
),
returns AS (
  SELECT
    'returns' AS metric_type,
    sm.sm_carrier AS carrier,
    sum(cr.cr_return_amount) AS total_amount,
    (
      SELECT avg(cs2.cs_net_paid_inc_ship)
      FROM catalog_sales cs2
      JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
      WHERE d2.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    ) AS avg_net_paid_all_carriers
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND sm.sm_carrier IN (
      SELECT sm2.sm_carrier
      FROM ship_mode sm2
      WHERE sm2.sm_carrier IN ('MSC', 'LATVIAN')
    )
  GROUP BY sm.sm_carrier
)
SELECT DISTINCT
  metric_type,
  carrier,
  total_amount,
  avg_net_paid_all_carriers
FROM (
  SELECT metric_type, carrier, total_amount, avg_net_paid_all_carriers FROM sales
  UNION ALL
  SELECT metric_type, carrier, total_amount, avg_net_paid_all_carriers FROM returns
) combined
ORDER BY carrier, metric_type
LIMIT 100
