WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_wholesale_cost > 30
      AND cs_ship_date_sk BETWEEN 2450800 AND 2450900
      AND cs_quantity > 1
),
agg_sales AS (
    SELECT
        cs_catalog_page_sk,
        COUNT(*) AS sales_cnt,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        AVG(cs_wholesale_cost) AS avg_wholesale_cost
    FROM sampled_sales
    GROUP BY cs_catalog_page_sk
),
joined AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_type,
        agg.sales_cnt,
        agg.total_net_paid,
        agg.total_quantity,
        agg.avg_wholesale_cost
    FROM catalog_page AS cp
    JOIN agg_sales AS agg
        ON cp.cp_catalog_page_sk = agg.cs_catalog_page_sk
    WHERE cp.cp_department IN ('Electronics', 'Books', 'Home')
      AND cp.cp_catalog_number BETWEEN 1 AND 5
      AND cp.cp_type = 'standard'
),
ranked_sales AS (
    SELECT
        cp_department,
        cp_catalog_number,
        total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_net_paid DESC) AS dept_rank,
        CASE WHEN total_net_paid > 1000 THEN 'High' ELSE 'Low' END AS sales_bucket
    FROM joined
),
aggregated AS (
    SELECT
        cp_department,
        cp_catalog_number,
        sales_bucket,
        SUM(total_net_paid) AS sum_net_paid,
        MAX(dept_rank) AS max_rank
    FROM ranked_sales
    GROUP BY CUBE(cp_department, cp_catalog_number, sales_bucket)
),
high_sales AS (
    SELECT cp_department, cp_catalog_number, sum_net_paid
    FROM aggregated
    WHERE sales_bucket = 'High'
),
low_sales AS (
    SELECT cp_department, cp_catalog_number, sum_net_paid
    FROM aggregated
    WHERE sales_bucket = 'Low'
)
SELECT *
FROM high_sales
EXCEPT
SELECT *
FROM low_sales
ORDER BY sum_net_paid DESC
LIMIT 100
