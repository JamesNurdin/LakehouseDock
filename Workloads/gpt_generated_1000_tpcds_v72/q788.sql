WITH sales_agg AS (
  SELECT
    p.p_promo_id AS promo_id,
    'promotion' AS source,
    SUM(ss.ss_net_profit) AS total_amount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2021
    AND EXISTS (
      SELECT 1
      FROM store_sales ss2
      JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
      WHERE ss2.ss_promo_sk = p.p_promo_sk
        AND ss2.ss_quantity > 5
        AND d2.d_year = 2021
      LIMIT 1
    )
  GROUP BY p.p_promo_id
),
returns_agg AS (
  SELECT
    c.cc_call_center_id AS promo_id,
    'call_center' AS source,
    SUM(cr.cr_net_loss) AS total_amount
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center c ON cr.cr_call_center_sk = c.cc_call_center_sk
  WHERE d.d_year = 2021
  GROUP BY c.cc_call_center_id
)
SELECT
  promo_id,
  source,
  total_amount,
  (
    SELECT SUM(ss3.ss_net_profit)
    FROM store_sales ss3
    JOIN date_dim d3 ON ss3.ss_sold_date_sk = d3.d_date_sk
    WHERE d3.d_year = 2021
  ) AS year_total_profit
FROM sales_agg
UNION ALL
SELECT
  promo_id,
  source,
  total_amount,
  (
    SELECT SUM(ss3.ss_net_profit)
    FROM store_sales ss3
    JOIN date_dim d3 ON ss3.ss_sold_date_sk = d3.d_date_sk
    WHERE d3.d_year = 2021
  ) AS year_total_profit
FROM returns_agg
ORDER BY total_amount DESC
LIMIT 100
