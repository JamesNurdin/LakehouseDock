WITH
  sales_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      'sales' AS metric_type,
      SUM(cs.cs_net_paid) AS metric_amount,
      (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS ((d.d_year, i.i_category), (d.d_year), ())
  ),
  returns_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      'returns' AS metric_type,
      SUM(cr.cr_return_amount) AS metric_amount,
      (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_net_profit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS ((d.d_year, i.i_category), (d.d_year), ())
  )
SELECT
  final.year,
  final.category,
  final.metric_type,
  final.metric_amount,
  final.avg_net_profit,
  ROW_NUMBER() OVER (ORDER BY final.metric_amount DESC) AS row_num,
  SUM(final.metric_amount) OVER (
    PARTITION BY final.metric_type
    ORDER BY final.metric_amount DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total
FROM (
  SELECT d_year AS year,
         i_category AS category,
         metric_type,
         metric_amount,
         avg_net_profit
  FROM sales_agg
  UNION ALL
  SELECT d_year AS year,
         i_category AS category,
         metric_type,
         metric_amount,
         avg_net_profit
  FROM returns_agg
) AS final
ORDER BY final.metric_amount DESC
LIMIT 100
