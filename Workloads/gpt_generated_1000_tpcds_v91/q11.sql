WITH sales_returns_agg AS (
  SELECT
    COALESCE(d_sold.d_year, d_ret.d_year) AS year,
    'net_sales' AS metric,
    SUM(COALESCE(cs.cs_net_paid_inc_ship_tax, 0) - COALESCE(cr.cr_net_loss, 0)) AS amount
  FROM catalog_sales cs
  FULL OUTER JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  LEFT JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
  WHERE d_sold.d_year = 2001 OR d_ret.d_year = 2001
  GROUP BY COALESCE(d_sold.d_year, d_ret.d_year)
),
promo_agg AS (
  SELECT
    d.d_year AS year,
    'promo_cost' AS metric,
    SUM(p.p_cost) AS amount
  FROM promotion p
  JOIN date_dim d
    ON p.p_start_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year
)
SELECT year, metric, amount
FROM sales_returns_agg
UNION ALL
SELECT year, metric, amount
FROM promo_agg
ORDER BY year, metric
LIMIT 100
