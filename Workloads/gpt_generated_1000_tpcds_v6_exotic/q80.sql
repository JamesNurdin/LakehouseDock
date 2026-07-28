WITH catalog_agg AS (
    SELECT
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'High' ELSE 'Low' END AS sales_level,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS category_rank,
        'Catalog' AS source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND ib.ib_lower_bound >= 100000
    GROUP BY i.i_category
),
store_agg AS (
    SELECT
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 50000 THEN 'High' ELSE 'Low' END AS sales_level,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS category_rank,
        'Store' AS source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND ib.ib_lower_bound >= 100000
    GROUP BY i.i_category
)
SELECT category,
       total_sales,
       sales_level,
       category_rank,
       source
FROM catalog_agg
UNION ALL
SELECT category,
       total_sales,
       sales_level,
       category_rank,
       source
FROM store_agg
ORDER BY total_sales DESC, category ASC
