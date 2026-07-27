WITH sales_dept AS (
    SELECT
        cp.cp_department,
        substring(cp.cp_department FROM 1 FOR 3) AS dept_prefix,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_order_number,
        cp.cp_description,
        cp.cp_type
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)special')
      AND cp.cp_type LIKE 'WEB%'
      AND c.c_first_name LIKE 'A%'
)
SELECT
    dept_prefix,
    cp_department,
    COUNT(DISTINCT cs_order_number) AS num_orders,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    CASE
        WHEN SUM(cs_net_profit) > 10000 THEN 'High'
        WHEN SUM(cs_net_profit) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_dept
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_order_number = sales_dept.cs_order_number
      AND regexp_like(r.r_reason_desc, '(?i)price')
)
GROUP BY dept_prefix, cp_department
ORDER BY total_profit DESC
LIMIT 100
