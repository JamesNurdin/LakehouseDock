WITH promo_sales AS (
    SELECT
        d_sold.d_year AS year,
        d_sold.d_moy AS month,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
        'Promo_TV_N' AS source
    FROM tpcds.catalog_sales cs
    INNER JOIN tpcds.date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'N'
      AND cs.cs_ext_discount_amt > 1000
    GROUP BY d_sold.d_year, d_sold.d_moy
),

birth_month_sales AS (
    SELECT
        d_sold.d_year AS year,
        d_sold.d_moy AS month,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
        'BirthMonth_8' AS source
    FROM tpcds.catalog_sales cs
    INNER JOIN tpcds.date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month = 8
      AND cs.cs_ext_tax < 100
    GROUP BY d_sold.d_year, d_sold.d_moy
)

SELECT year, month, total_sales, source
FROM promo_sales
UNION ALL
SELECT year, month, total_sales, source
FROM birth_month_sales
ORDER BY year, month, source
LIMIT 100
