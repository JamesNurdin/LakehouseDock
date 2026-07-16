SELECT
    hd.hd_income_band_sk,
    c.c_preferred_cust_flag,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    AVG(d_store.d_year - c.c_birth_year) AS avg_age_at_first_sale,
    MIN(d_store.d_date) AS earliest_first_sale,
    MAX(d_store.d_date) AS latest_first_sale
FROM store s
JOIN date_dim d_store
  ON s.s_closed_date_sk = d_store.d_date_sk
JOIN customer c
  ON c.c_first_sales_date_sk = d_store.d_date_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE s.s_state = 'CA'
  AND hd.hd_buy_potential = 'HIGH'
  AND c.c_preferred_cust_flag = 'Y'
  AND d_store.d_year BETWEEN 2010 AND 2020
GROUP BY hd.hd_income_band_sk, c.c_preferred_cust_flag
ORDER BY num_customers DESC
LIMIT 100
