/*
  Goal: For each year‑month, calculate the number of catalog sales, total net profit and average sales price for catalog pages whose description contains a three‑digit code (e.g., "CODE123"), whose type starts with "C", and that were sold in the current month. The result also shows a concatenated department‑code string.
*/
WITH sales_page AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cp.cp_department,
        cp.cp_description,
        cp.cp_type
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    CONCAT(sales_page.cp_department, '-', REGEXP_EXTRACT(sales_page.cp_description, 'CODE([0-9]{3})', 1)) AS dept_code,
    COUNT(*) AS sales_cnt,
    SUM(sales_page.cs_net_profit) AS total_net_profit,
    AVG(sales_page.cs_ext_sales_price) AS avg_sale_price
FROM sales_page
JOIN date_dim d
    ON sales_page.cs_sold_date_sk = d.d_date_sk
WHERE
    REGEXP_LIKE(sales_page.cp_description, 'CODE[0-9]{3}')
    AND REGEXP_EXTRACT(sales_page.cp_description, 'CODE([0-9]{3})', 1) IS NOT NULL
    AND sales_page.cp_type LIKE 'C%'
    AND d.d_current_month = 'Y'
GROUP BY
    d.d_year,
    d.d_month_seq,
    CONCAT(sales_page.cp_department, '-', REGEXP_EXTRACT(sales_page.cp_description, 'CODE([0-9]{3})', 1))
ORDER BY
    d.d_year DESC,
    d.d_month_seq DESC
LIMIT 100
