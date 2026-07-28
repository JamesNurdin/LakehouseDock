WITH morning_sales AS (
    SELECT
        'Morning' AS period,
        i.i_brand,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour BETWEEN 6 AND 11
      AND i.i_size = 'small'
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_brand, p.p_promo_name
),

evening_sales AS (
    SELECT
        'Evening' AS period,
        i.i_brand,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour >= 18
      AND i.i_size = 'large'
      AND cd.cd_dep_count > 2
    GROUP BY i.i_brand, p.p_promo_name
)
SELECT period, i_brand, p_promo_name, total_sales, order_cnt
FROM morning_sales
UNION ALL
SELECT period, i_brand, p_promo_name, total_sales, order_cnt
FROM evening_sales
ORDER BY period, total_sales DESC
