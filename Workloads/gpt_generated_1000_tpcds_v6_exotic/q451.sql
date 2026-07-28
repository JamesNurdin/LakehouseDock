WITH sales_by_customer_category AS (
    SELECT
        c.c_customer_id AS customer_id,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS total_ext_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt,
        COALESCE(cd.cd_gender, 'Unknown') AS ship_gender
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1979
      AND cs.cs_ext_tax > 50
      AND i.i_class IN ('hockey', 'accessories')
    GROUP BY c.c_customer_id, i.i_category, cd.cd_gender
)
SELECT
    category,
    AVG(total_ext_sales) AS avg_total_ext_sales,
    SUM(total_quantity) AS total_quantity_all,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM sales_by_customer_category
GROUP BY category
HAVING AVG(total_ext_sales) > 1000
ORDER BY avg_total_ext_sales DESC
LIMIT 100
