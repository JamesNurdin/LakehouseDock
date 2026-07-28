WITH
    promo_sales AS (
        SELECT
            d.d_year,
            p.p_promo_name,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            COUNT(DISTINCT ss.ss_ticket_number) AS orders
        FROM store_sales ss
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE p.p_discount_active = 'Y'
          AND d.d_year = 2001
        GROUP BY d.d_year, p.p_promo_name
    ),
    nonpromo_sales AS (
        SELECT
            d.d_year,
            'NO_PROMO' AS p_promo_name,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            COUNT(DISTINCT ss.ss_ticket_number) AS orders
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE p.p_promo_sk IS NULL
          AND d.d_year = 2001
        GROUP BY d.d_year
    ),
    combined AS (
        SELECT * FROM promo_sales
        UNION ALL
        SELECT * FROM nonpromo_sales
    )
SELECT
    c.d_year,
    c.p_promo_name,
    c.total_sales,
    c.orders,
    (
        SELECT AVG(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ) AS avg_yearly_sales
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss3
    JOIN promotion p3 ON ss3.ss_promo_sk = p3.p_promo_sk
    WHERE p3.p_promo_name = c.p_promo_name
      AND ss3.ss_coupon_amt > 5000
)
ORDER BY c.total_sales DESC
LIMIT 100
