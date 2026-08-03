WITH catalog_data AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS department,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales_sum,
        ARRAY[SUM(cs.cs_quantity), SUM(cs.cs_ext_discount_amt)] AS metrics_arr
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY d.d_year, cp.cp_department
),
catalog_expand AS (
    SELECT
        year,
        department,
        total_sales,
        distinct_customers,
        distinct_sales_sum,
        metric,
        pos
    FROM catalog_data
    CROSS JOIN UNNEST(metrics_arr) WITH ORDINALITY AS t(metric, pos)
),
store_data AS (
    SELECT
        d.d_year AS year,
        r.r_reason_desc AS department,
        SUM(sr.sr_return_amt) AS total_sales,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        SUM(DISTINCT sr.sr_return_amt) AS distinct_sales_sum,
        ARRAY[SUM(sr.sr_return_quantity), SUM(sr.sr_return_tax)] AS metrics_arr
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY d.d_year, r.r_reason_desc
),
store_expand AS (
    SELECT
        year,
        department,
        total_sales,
        distinct_customers,
        distinct_sales_sum,
        metric,
        pos
    FROM store_data
    CROSS JOIN UNNEST(metrics_arr) WITH ORDINALITY AS t(metric, pos)
),
combined AS (
    SELECT * FROM catalog_expand
    UNION ALL
    SELECT * FROM store_expand
)
SELECT
    year,
    department,
    SUM(total_sales) AS sum_total_sales,
    SUM(distinct_customers) AS sum_distinct_customers,
    SUM(distinct_sales_sum) AS sum_distinct_sales_sum,
    metric,
    pos,
    COUNT(*) AS rows_per_metric
FROM combined
GROUP BY year, department, metric, pos
ORDER BY year DESC, sum_total_sales DESC
LIMIT 100
