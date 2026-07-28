WITH sales_by_promo AS (
    SELECT
        p.p_promo_name,
        c.c_birth_month,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_tax) AS total_tax,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_tax > 10
        AND cs.cs_list_price BETWEEN 50 AND 200
        AND p.p_channel_catalog = 'N'
        AND c.c_birth_month IN (9, 12, 4)
        AND c.c_last_review_date BETWEEN 2452300 AND 2452650
        AND p.p_promo_name LIKE '%bar%'
    GROUP BY p.p_promo_name, c.c_birth_month
)
SELECT
    p_promo_name,
    c_birth_month,
    total_net_paid,
    total_tax,
    sales_cnt,
    CASE WHEN total_tax > 100 THEN 'HIGH' ELSE 'LOW' END AS tax_level,
    RANK() OVER (PARTITION BY c_birth_month ORDER BY total_net_paid DESC) AS net_paid_rank
FROM sales_by_promo
ORDER BY c_birth_month, net_paid_rank
LIMIT 100
