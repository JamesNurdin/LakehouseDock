WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(cp.cp_description, '[A-Za-z]{3,}\d{2}')
      AND cp.cp_type LIKE 'A%'
)
SELECT
    d_year,
    substring(cp_department, 1, 3) AS dept_prefix,
    regexp_extract(cp_description, '([A-Za-z]+)', 1) AS first_word,
    concat(cp_department, '-', cp_type) AS dept_type,
    sum(cs_net_profit) AS total_net_profit,
    count(*) AS sales_cnt,
    CASE WHEN sum(cs_net_profit) > 50000 THEN 'High' ELSE 'Low' END AS profit_category
FROM filtered_sales
GROUP BY
    d_year,
    substring(cp_department, 1, 3),
    regexp_extract(cp_description, '([A-Za-z]+)', 1),
    concat(cp_department, '-', cp_type)
HAVING sum(cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
