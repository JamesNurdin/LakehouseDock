WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUBSTRING(c.c_first_name, 1, 1) || '.' || c.c_last_name AS cust_initial,
        cp.cp_department,
        cp.cp_description,
        REGEXP_EXTRACT(cp.cp_description, '(?i)(\\w*sales\\w*)', 1) AS sales_keyword,
        i.i_product_name,
        d.d_year,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(cp.cp_description, '(?i)sales')
      AND i.i_product_name LIKE 'ABC%'
    GROUP BY
        cs.cs_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cp.cp_department,
        cp.cp_description,
        i.i_product_name,
        d.d_year
)
SELECT
    sa.customer_name,
    sa.cust_initial,
    sa.cp_department,
    sa.sales_keyword,
    sa.total_profit,
    sa.sales_cnt,
    RANK() OVER (PARTITION BY sa.cp_department ORDER BY sa.total_profit DESC) AS dept_rank,
    (
        SELECT AVG(total_profit)
        FROM sales_agg sub
        WHERE sub.cp_department = sa.cp_department
    ) AS avg_dept_profit
FROM sales_agg sa
WHERE sa.total_profit > (
    SELECT AVG(total_profit)
    FROM sales_agg
)
ORDER BY sa.total_profit DESC
LIMIT 10
