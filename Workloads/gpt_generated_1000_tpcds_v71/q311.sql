WITH catalog_weekend AS (
    SELECT
        d.d_date AS sale_date,
        p.p_promo_name AS promo_name,
        'Catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_weekend = 'Y'
      AND d.d_year = 2001
    GROUP BY d.d_date, p.p_promo_name
),
store_weekend AS (
    SELECT
        d.d_date AS sale_date,
        p.p_promo_name AS promo_name,
        'Store' AS channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_weekend = 'Y'
      AND d.d_year = 2001
    GROUP BY d.d_date, p.p_promo_name
),
combined AS (
    SELECT * FROM catalog_weekend
    UNION ALL
    SELECT * FROM store_weekend
)
SELECT
    sale_date,
    promo_name,
    channel,
    total_sales,
    orders,
    ROW_NUMBER() OVER (PARTITION BY sale_date ORDER BY total_sales DESC) AS rank_by_sales
FROM combined
ORDER BY sale_date, rank_by_sales
LIMIT 100
