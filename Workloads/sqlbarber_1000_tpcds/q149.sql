SELECT d_year, COUNT(DISTINCT c_customer_sk) AS num_customers FROM customer JOIN date_dim ON customer.c_first_shipto_date_sk = date_dim.d_date_sk WHERE c_preferred_cust_flag = 'N' GROUP BY d_year
