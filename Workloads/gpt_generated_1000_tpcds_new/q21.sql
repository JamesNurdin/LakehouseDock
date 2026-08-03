SELECT
    CONCAT(cp.cp_department, ': ', cp.cp_type) AS dept_type,
    REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1) AS promo_number,
    d.d_year,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
FROM tpcds.catalog_sales cs
JOIN tpcds.date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE d.d_year = 2002
  AND REGEXP_LIKE(cp.cp_description, '(?i)discount')
  AND cp.cp_type LIKE 'monthly%'
  AND cs.cs_bill_customer_sk IN (
        SELECT c.c_customer_sk
        FROM tpcds.customer c
        WHERE c.c_email_address LIKE '%@example.com'
      )
GROUP BY
    CONCAT(cp.cp_department, ': ', cp.cp_type),
    REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1),
    d.d_year
ORDER BY total_profit DESC
LIMIT 100
