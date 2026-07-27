/*
Goal: Compare total sales and total return amounts for each item (and its category) among customers who have an Advanced Degree. For each side we compute a category‑rank, include the overall average sales amount across all catalog sales as a scalar value, and flag whether the item ever appears in catalog returns. The two result sets (sales and returns) are combined with UNION ALL and limited to the top 100 rows.
*/
WITH sales AS (
    SELECT
        i.i_item_id,
        i.i_category,
        'sales' AS metric_type,
        SUM(cs.cs_ext_sales_price) AS metric_value,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS metric_rank,
        (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2) AS overall_avg_sales,
        EXISTS (SELECT 1 FROM catalog_returns cr WHERE cr.cr_item_sk = i.i_item_sk) AS has_return
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'Advanced Degree'
    GROUP BY i.i_item_id, i.i_category, i.i_item_sk
),
returns AS (
    SELECT
        i.i_item_id,
        i.i_category,
        'returns' AS metric_type,
        SUM(sr.sr_return_amt_inc_tax) AS metric_value,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS metric_rank,
        (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2) AS overall_avg_sales,
        EXISTS (SELECT 1 FROM catalog_returns cr WHERE cr.cr_item_sk = i.i_item_sk) AS has_return
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'Advanced Degree'
    GROUP BY i.i_item_id, i.i_category, i.i_item_sk
)
SELECT *
FROM sales
UNION ALL
SELECT *
FROM returns
ORDER BY metric_type, metric_rank
LIMIT 100
