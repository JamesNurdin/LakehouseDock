WITH sales_agg AS (
  SELECT
    cd.cd_demo_sk,
    d.d_year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt,
    CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2000
    AND cs.cs_ext_sales_price > (SELECT AVG(cr_return_amount) FROM catalog_returns)
  GROUP BY cd.cd_demo_sk, d.d_year
  HAVING SUM(cs.cs_ext_sales_price) > 1000
),

returns_agg AS (
  SELECT
    cd.cd_demo_sk,
    d.d_year,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(*) AS returns_cnt,
    CASE WHEN SUM(sr.sr_return_amt) > 50000 THEN 'HIGH' ELSE 'LOW' END AS returns_category
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2000
  GROUP BY cd.cd_demo_sk, d.d_year
  HAVING SUM(sr.sr_return_amt) > 100
),

full_demo AS (
  SELECT
    COALESCE(s.cd_demo_sk, r.cd_demo_sk) AS cd_demo_sk,
    COALESCE(s.d_year, r.d_year) AS d_year,
    s.total_sales,
    s.sales_cnt,
    s.sales_category,
    r.total_returns,
    r.returns_cnt,
    r.returns_category
  FROM sales_agg s
  FULL OUTER JOIN returns_agg r
    ON s.cd_demo_sk = r.cd_demo_sk
),

-- LATERAL subquery to compute average sales per demo across all years

demo_with_lateral AS (
  SELECT
    fd.*,
    l.avg_sales_all_years
  FROM full_demo fd
  CROSS JOIN LATERAL (
    SELECT AVG(cs.cs_ext_sales_price) AS avg_sales_all_years
    FROM catalog_sales cs
    WHERE cs.cs_bill_cdemo_sk = fd.cd_demo_sk
  ) l
),

high_sales AS (
  SELECT
    cd_demo_sk,
    d_year,
    total_sales,
    total_returns,
    sales_category,
    returns_category,
    avg_sales_all_years,
    'SALES' AS metric_source
  FROM demo_with_lateral
  WHERE sales_category = 'HIGH'
),

high_returns AS (
  SELECT
    cd_demo_sk,
    d_year,
    total_sales,
    total_returns,
    sales_category,
    returns_category,
    avg_sales_all_years,
    'RETURNS' AS metric_source
  FROM demo_with_lateral
  WHERE returns_category = 'HIGH'
)

SELECT
  cd_demo_sk,
  d_year,
  total_sales,
  total_returns,
  sales_category,
  returns_category,
  avg_sales_all_years,
  metric_source
FROM high_sales
UNION
SELECT
  cd_demo_sk,
  d_year,
  total_sales,
  total_returns,
  sales_category,
  returns_category,
  avg_sales_all_years,
  metric_source
FROM high_returns
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
