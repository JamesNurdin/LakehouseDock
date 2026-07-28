WITH combined AS (
    SELECT
        i.i_brand_id AS brand_id,
        i.i_brand AS brand,
        d.d_year AS year,
        CASE WHEN i.i_current_price > 20 THEN 'expensive' ELSE 'regular' END AS price_category,
        SUM(ss.ss_net_paid) AS sales_amount,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_brand_id, i.i_brand, d.d_year, CASE WHEN i.i_current_price > 20 THEN 'expensive' ELSE 'regular' END
    UNION ALL
    SELECT
        i.i_brand_id AS brand_id,
        i.i_brand AS brand,
        d.d_year AS year,
        CASE WHEN i.i_current_price > 20 THEN 'expensive' ELSE 'regular' END AS price_category,
        SUM(cs.cs_net_paid) AS sales_amount,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_brand_id, i.i_brand, d.d_year, CASE WHEN i.i_current_price > 20 THEN 'expensive' ELSE 'regular' END
)
SELECT
    brand_id,
    brand,
    year,
    price_category,
    channel,
    SUM(sales_amount) AS total_sales
FROM combined
GROUP BY GROUPING SETS (
    (brand_id, brand, year, price_category, channel),
    (brand_id, brand, year, price_category),
    (brand_id, brand, year),
    (brand_id, brand),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
