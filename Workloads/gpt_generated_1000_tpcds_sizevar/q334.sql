WITH filtered_store AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_state,
        s_zip,
        s_tax_percentage,
        s_division_name,
        s_number_employees,
        s_floor_space
    FROM tpcds.store
    WHERE s_state IN ('CA', 'TX', 'NY')
      AND s_tax_percentage >= 0.03
      AND s_zip BETWEEN '45000' AND '56000'
      AND s_number_employees BETWEEN 100 AND 400
      AND s_floor_space > 25000
)
SELECT
    fs.s_state,
    fs.s_division_name,
    COUNT(ss.ss_ticket_number) AS transaction_cnt,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_sales_price) AS avg_unit_price,
    MIN(ss.ss_sales_price) AS min_unit_price,
    MAX(ss.ss_sales_price) AS max_unit_price
FROM filtered_store fs
FULL OUTER JOIN tpcds.store_sales ss
    ON ss.ss_store_sk = fs.s_store_sk
WHERE ss.ss_quantity >= 10
  AND ss.ss_list_price BETWEEN 20 AND 200
  AND ss.ss_ext_discount_amt > 0
  AND ss.ss_ext_tax < 30
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450500
GROUP BY fs.s_state, fs.s_division_name
ORDER BY total_sales DESC
LIMIT 100
