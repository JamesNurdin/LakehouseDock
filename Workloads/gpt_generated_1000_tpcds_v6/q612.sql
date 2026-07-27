WITH filtered_sales AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cp.cp_catalog_page_number,
        cp.cp_department,
        cp.cp_description,
        cp.cp_type,
        cd.cd_credit_rating
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cp.cp_description, '(?i)sale|discount')
      AND cp.cp_type LIKE 'A%'
      AND regexp_like(cd.cd_credit_rating, '^[A-D]$')
)
SELECT
    cp_catalog_page_number,
    cp_department,
    COUNT(*) AS sales_cnt,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cs_ext_sales_price) AS total_sales,
    CASE
        WHEN SUM(cs_net_profit) > 10000 THEN 'High'
        WHEN SUM(cs_net_profit) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    CONCAT('Dept ', cp_department) AS dept_label,
    SUBSTRING(cp_description, 1, 30) AS short_desc
FROM filtered_sales
GROUP BY
    cp_catalog_page_number,
    cp_department,
    CONCAT('Dept ', cp_department),
    SUBSTRING(cp_description, 1, 30)
ORDER BY total_net_profit DESC
LIMIT 100
