WITH active_promos AS (
        SELECT DISTINCT p_promo_sk,
                        p_promo_name
        FROM promotion
        WHERE p_discount_active = 'Y'
    ),
    catalog_promo_sales AS (
        SELECT
            ap.p_promo_name AS promo_name,
            'Catalog' AS sales_channel,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            (SELECT AVG(cs2.cs_ext_discount_amt)
             FROM catalog_sales cs2
             WHERE cs2.cs_promo_sk = ap.p_promo_sk) AS avg_discount
        FROM catalog_sales cs
        JOIN active_promos ap ON cs.cs_promo_sk = ap.p_promo_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE d.d_year = 2020
          AND sm.sm_carrier = 'FEDEX'
        GROUP BY ap.p_promo_name, ap.p_promo_sk
    ),
    store_promo_sales AS (
        SELECT
            ap.p_promo_name AS promo_name,
            'Store' AS sales_channel,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            (SELECT AVG(ss2.ss_ext_discount_amt)
             FROM store_sales ss2
             WHERE ss2.ss_promo_sk = ap.p_promo_sk) AS avg_discount
        FROM store_sales ss
        JOIN active_promos ap ON ss.ss_promo_sk = ap.p_promo_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2020
        GROUP BY ap.p_promo_name, ap.p_promo_sk
    )
SELECT
    promo_name,
    sales_channel,
    total_sales,
    avg_discount
FROM catalog_promo_sales
UNION ALL
SELECT
    promo_name,
    sales_channel,
    total_sales,
    avg_discount
FROM store_promo_sales
ORDER BY total_sales DESC
LIMIT 100
