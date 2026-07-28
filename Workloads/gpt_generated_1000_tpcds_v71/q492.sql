WITH max_emp AS (
    SELECT cc_company, MAX(cc_employees) AS max_emp
    FROM tpcds.call_center
    GROUP BY cc_company
)
SELECT
    cc.cc_company,
    cc.cc_name,
    d_open.d_date AS open_date,
    d_close.d_date AS close_date,
    cp.cp_catalog_page_number,
    cust.c_customer_id,
    cust.c_email_address,
    RANK() OVER (PARTITION BY cc.cc_company ORDER BY cc.cc_employees DESC) AS emp_rank,
    max_emp.max_emp,
    CASE WHEN EXISTS (
        SELECT 1
        FROM tpcds.catalog_page cp2
        JOIN tpcds.date_dim d2sub ON cp2.cp_end_date_sk = d2sub.d_date_sk
        WHERE cp2.cp_catalog_number = cp.cp_catalog_number
          AND d2sub.d_year = d_open.d_year
          AND cp2.cp_description LIKE '%women%'
    ) THEN 1 ELSE 0 END AS has_women_desc
FROM tpcds.call_center cc
JOIN tpcds.date_dim d_open
  ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN tpcds.catalog_page cp
  ON cp.cp_start_date_sk = d_open.d_date_sk
JOIN tpcds.date_dim d_close
  ON cc.cc_closed_date_sk = d_close.d_date_sk
JOIN tpcds.customer cust
  ON cust.c_first_sales_date_sk = d_close.d_date_sk
JOIN max_emp
  ON max_emp.cc_company = cc.cc_company
WHERE cc.cc_class = 'large'
  AND cc.cc_company IN (1, 2, 3, 4)
  AND d_open.d_year = 2002
  AND cp.cp_catalog_page_number >= 5
  AND cust.c_email_address LIKE '%@%.org'
ORDER BY cc.cc_company, emp_rank
LIMIT 100
