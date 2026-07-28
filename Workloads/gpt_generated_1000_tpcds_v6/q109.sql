WITH store_sales_agg AS (
    SELECT
        d.d_month_seq AS month_seq,
        i.i_brand AS brand,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        'store' AS sales_source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND d.d_current_month = 'Y'
      AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
    GROUP BY d.d_month_seq, i.i_brand
    HAVING SUM(ss.ss_ext_sales_price) > 10000
),
catalog_sales_agg AS (
    SELECT
        d.d_month_seq AS month_seq,
        i.i_brand AS brand,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        'catalog' AS sales_source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND d.d_current_quarter = 'Y'
      AND EXISTS (SELECT 1 FROM reason r WHERE r.r_reason_desc LIKE '%damaged%')
    GROUP BY d.d_month_seq, i.i_brand
    HAVING SUM(cs.cs_ext_sales_price) > 10000
)
SELECT month_seq, brand, total_sales, sales_source
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
) combined
ORDER BY total_sales DESC
LIMIT 100
