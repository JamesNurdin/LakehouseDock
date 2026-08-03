WITH sales_data AS (
  SELECT
    cs.cs_sold_date_sk,
    d.d_year,
    cs.cs_item_sk,
    i.i_category,
    cs.cs_ext_sales_price,
    cs.cs_ext_tax,
    cs.cs_bill_hdemo_sk,
    ARRAY[cs.cs_ext_sales_price, cs.cs_ext_tax] AS metrics
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND cs.cs_ext_sales_price > 100
),
returns_data AS (
  SELECT
    wr.wr_returned_date_sk,
    d.d_year,
    wr.wr_item_sk,
    i.i_category,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_refunded_hdemo_sk,
    ARRAY[wr.wr_return_amt, wr.wr_return_tax] AS metrics
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND wr.wr_return_amt > 50
)
SELECT
  d_year,
  i_category,
  metric_type,
  SUM(metric_value) AS total_amount
FROM (
  SELECT
    s.d_year,
    s.i_category,
    mt.metric_type,
    u.metric_value
  FROM sales_data s
  CROSS JOIN UNNEST(s.metrics) WITH ORDINALITY AS u(metric_value, ord)
  LEFT JOIN (VALUES (1, 'sales_price'), (2, 'tax')) AS mt(metric_id, metric_type) ON mt.metric_id = ord
  WHERE EXISTS (
    SELECT 1
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_demo_sk = s.cs_bill_hdemo_sk
      AND ib.ib_lower_bound > 100000
  )
) AS sales_metrics
GROUP BY d_year, i_category, metric_type
HAVING SUM(metric_value) > 1000

UNION ALL

SELECT
  d_year,
  i_category,
  metric_type,
  SUM(metric_value) AS total_amount
FROM (
  SELECT
    r.d_year,
    r.i_category,
    mt.metric_type,
    u.metric_value
  FROM returns_data r
  CROSS JOIN UNNEST(r.metrics) WITH ORDINALITY AS u(metric_value, ord)
  LEFT JOIN (VALUES (1, 'return_amount'), (2, 'return_tax')) AS mt(metric_id, metric_type) ON mt.metric_id = ord
  WHERE EXISTS (
    SELECT 1
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_demo_sk = r.wr_refunded_hdemo_sk
      AND ib.ib_lower_bound > 100000
  )
) AS return_metrics
GROUP BY d_year, i_category, metric_type
HAVING SUM(metric_value) > 500

ORDER BY d_year, i_category, metric_type
