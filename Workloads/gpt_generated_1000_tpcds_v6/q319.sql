/*
Goal: Compare monthly sales performance by product category from store sales (California stores) and catalog sales (TV promotions) for the year 2002, classify sales level, and rank categories within each month.
*/
WITH date_info AS (
    SELECT d_date_sk,
           date_trunc('month', d_date) AS month_start,
           d_year
    FROM   date_dim
    WHERE  d_year = 2002
),
store_agg AS (
    SELECT
        di.month_start,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_level,
        'Store' AS sales_source
    FROM   store_sales ss
    JOIN   date_info di ON ss.ss_sold_date_sk = di.d_date_sk
    JOIN   item i ON ss.ss_item_sk = i.i_item_sk
    JOIN   store s ON ss.ss_store_sk = s.s_store_sk
    WHERE  s.s_state = 'CA'
    GROUP BY di.month_start, i.i_category
),
catalog_agg AS (
    SELECT
        di.month_start,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 150000 THEN 'High' ELSE 'Low' END AS sales_level,
        'Catalog' AS sales_source
    FROM   catalog_sales cs
    JOIN   date_info di ON cs.cs_sold_date_sk = di.d_date_sk
    JOIN   item i ON cs.cs_item_sk = i.i_item_sk
    JOIN   promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE  p.p_channel_tv = 'Y'
    GROUP BY di.month_start, i.i_category
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
)
SELECT
    month_start,
    i_category,
    total_sales,
    sales_level,
    sales_source,
    ROW_NUMBER() OVER (PARTITION BY month_start ORDER BY total_sales DESC) AS rank_within_month
FROM   combined
ORDER BY month_start DESC, total_sales DESC
LIMIT 100
