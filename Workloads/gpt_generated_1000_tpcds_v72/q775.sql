WITH sales_agg AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_ext_sales,
        AVG(cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        SUM(cs_quantity) AS total_qty,
        MAX(cs_coupon_amt) AS max_coupon
    FROM tpcds.catalog_sales
    WHERE cs_ext_sales_price > 1000
      AND cs_quantity >= 30
      AND cs_coupon_amt BETWEEN 30 AND 2000
    GROUP BY cs_bill_customer_sk
),
unioned AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_country,
        wp.wp_type,
        s.total_ext_sales,
        s.avg_discount,
        s.distinct_orders,
        CASE WHEN s.total_ext_sales > 20000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM tpcds.customer c
    JOIN sales_agg s ON s.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'JAPAN'
      AND wp.wp_autogen_flag = 'N'
      AND cd.cd_gender = 'M'
    UNION ALL
    SELECT
        c.c_customer_sk,
        c.c_birth_country,
        wp.wp_type,
        s.total_ext_sales,
        s.avg_discount,
        s.distinct_orders,
        CASE WHEN s.total_ext_sales > 20000 THEN 'HIGH' ELSE 'LOW' END
    FROM tpcds.customer c
    JOIN sales_agg s ON s.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'KOREA'
      AND wp.wp_autogen_flag = 'Y'
      AND cd.cd_gender = 'F'
)
SELECT DISTINCT
    u.c_birth_country,
    u.wp_type,
    SUM(u.total_ext_sales) AS sum_sales,
    AVG(u.avg_discount) AS avg_discount,
    COUNT(DISTINCT u.c_customer_sk) AS cust_count,
    MAX(u.sales_category) FILTER (WHERE u.sales_category = 'HIGH') AS has_high_sales
FROM unioned u
WHERE EXISTS (
    SELECT 1
    FROM tpcds.catalog_sales cs_corr
    WHERE cs_corr.cs_bill_customer_sk = u.c_customer_sk
      AND cs_corr.cs_ext_sales_price > 5000
)
GROUP BY u.c_birth_country, u.wp_type
ORDER BY sum_sales DESC
LIMIT 100
