WITH filtered_sales AS (
    SELECT
        cp.cp_type,
        dd.d_month_seq,
        regexp_extract(cp.cp_description, '(\\d{3,})', 1) AS extracted_code,
        concat(cp.cp_type, '-', substr(c.c_first_name, 1, 1)) AS type_initial,
        cs.cs_net_profit,
        cs.cs_ext_sales_price
    FROM catalog_sales AS cs
    JOIN catalog_page AS cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim AS dd
      ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN customer AS c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE dd.d_year = 2022
      AND regexp_like(cp.cp_description, '\\d{3,}')
      AND c.c_last_name LIKE 'S%'
)
SELECT
    cp_type,
    d_month_seq,
    extracted_code,
    type_initial,
    sum(cs_net_profit) AS total_net_profit,
    sum(cs_ext_sales_price) AS total_sales,
    count(*) AS sales_cnt
FROM filtered_sales
GROUP BY
    cp_type,
    d_month_seq,
    extracted_code,
    type_initial
ORDER BY total_net_profit DESC
LIMIT 100
