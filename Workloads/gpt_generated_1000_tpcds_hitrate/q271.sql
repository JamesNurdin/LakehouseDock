WITH
  store_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      sum(ss.ss_net_paid)                AS total_net_paid,
      sum(ss.ss_ext_sales_price)         AS total_ext_sales_price,
      array[sum(ss.ss_net_paid), sum(ss.ss_ext_sales_price)] AS metrics
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
  ),
  catalog_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      sum(cs.cs_net_paid)                AS total_net_paid,
      sum(cs.cs_ext_sales_price)         AS total_ext_sales_price,
      array[sum(cs.cs_net_paid), sum(cs.cs_ext_sales_price)] AS metrics
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
  ),
  combined AS (
    SELECT 'store'   AS channel, d_year, d_month_seq, total_net_paid, total_ext_sales_price, metrics FROM store_agg
    UNION ALL
    SELECT 'catalog' AS channel, d_year, d_month_seq, total_net_paid, total_ext_sales_price, metrics FROM catalog_agg
  )
SELECT
  channel,
  d_year,
  d_month_seq,
  metric_value,
  metric_index,
  LAG(metric_value) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq, metric_index) AS metric_value_lag
FROM combined
CROSS JOIN UNNEST(metrics) WITH ORDINALITY AS t(metric_value, metric_index)
ORDER BY d_year, d_month_seq, channel, metric_index
LIMIT 100
