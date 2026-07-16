WITH customer_returns AS (
    SELECT sr_customer_sk,
           SUM(sr_return_amt_inc_tax) AS total_return_amt,
           AVG(sr_return_quantity) AS avg_return_qty,
           COUNT(DISTINCT sr_item_sk) AS distinct_items,
           MAX(sr_returned_date_sk) AS last_return_date
    FROM store_returns
    WHERE sr_return_amt_inc_tax > 100
    GROUP BY sr_customer_sk
), filtered_customers AS (
    SELECT c_customer_sk,
           c_birth_country,
           c_preferred_cust_flag,
           c_birth_year,
           c_last_review_date
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
      AND c_birth_year BETWEEN 1970 AND 1990
      AND c_last_review_date >= 2452000
), joined_data AS (
    SELECT fc.c_birth_country,
           cr.total_return_amt,
           cr.avg_return_qty,
           cr.last_return_date,
           fc.c_last_review_date
    FROM filtered_customers fc
    JOIN customer_returns cr
      ON fc.c_customer_sk = cr.sr_customer_sk
    WHERE cr.last_return_date >= 2450000
)
SELECT agg.c_birth_country,
       agg.num_customers,
       agg.total_return_amount,
       agg.avg_return_qty,
       agg.most_recent_review_date,
       RANK() OVER (ORDER BY agg.total_return_amount DESC) AS country_rank
FROM (
    SELECT j.c_birth_country,
           COUNT(*) AS num_customers,
           SUM(j.total_return_amt) AS total_return_amount,
           AVG(j.avg_return_qty) AS avg_return_qty,
           MAX(j.c_last_review_date) AS most_recent_review_date
    FROM joined_data j
    GROUP BY j.c_birth_country
    HAVING SUM(j.total_return_amt) > 5000
) agg
ORDER BY agg.total_return_amount DESC
LIMIT 10
