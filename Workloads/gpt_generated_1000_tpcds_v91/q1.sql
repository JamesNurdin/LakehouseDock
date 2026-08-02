SELECT c_birth_year, COUNT(*) AS num_customers
FROM tpcds.customer
WHERE c_first_sales_date_sk BETWEEN 2449000 AND 2451000
GROUP BY c_birth_year
ORDER BY num_customers DESC
LIMIT 100
