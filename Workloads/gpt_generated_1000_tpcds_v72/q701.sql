WITH pref_customers AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           SUM(sr.sr_return_amt) AS total_return_amt,
           COUNT(*) AS ret_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month = 5
      AND sr.sr_return_tax > 5.00
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
nonpref_customers AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           SUM(sr.sr_return_amt) AS total_return_amt,
           COUNT(*) AS ret_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'N'
      AND c.c_birth_day = 23
      AND sr.sr_fee > 20.00
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT u.c_customer_id,
       u.c_first_name,
       u.c_last_name,
       u.total_return_amt,
       u.ret_cnt,
       CASE WHEN u.total_return_amt > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
       RANK() OVER (ORDER BY u.total_return_amt DESC) AS return_rank
FROM (
    SELECT * FROM pref_customers
    UNION ALL
    SELECT * FROM nonpref_customers
) u
ORDER BY u.total_return_amt DESC
LIMIT 100
