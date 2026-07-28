WITH billing AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        'Billing' AS src
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cs.cs_ext_list_price > 5000
    GROUP BY cd.cd_gender
),
shipping AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        'Shipping' AS src
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND cs.cs_ext_ship_cost < 500
    GROUP BY cd.cd_gender
)
SELECT src, gender, total_sales, order_cnt
FROM (
    SELECT src, gender, total_sales, order_cnt FROM billing
    UNION ALL
    SELECT src, gender, total_sales, order_cnt FROM shipping
) AS combined
ORDER BY src, total_sales DESC
