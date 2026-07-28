WITH filtered_sales AS (
    SELECT
        cp.cp_department,
        d.d_year,
        d.d_month_seq,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
      AND regexp_like(i.i_item_desc, '(?i)gold')
      AND cp.cp_description LIKE '%summer%'
)
SELECT
    cp_department,
    d_year,
    d_month_seq,
    COUNT(*) AS sales_cnt,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    MAX(REGEXP_EXTRACT(i_item_desc, '(?i)(gold\s+\w+)')) AS example_term,
    MAX(CONCAT(c_first_name, ' ', c_last_name)) AS example_customer
FROM filtered_sales
GROUP BY
    cp_department,
    d_year,
    d_month_seq
ORDER BY total_sales DESC
LIMIT 100
