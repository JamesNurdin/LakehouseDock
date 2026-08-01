WITH filtered_returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_returned_time_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_addr_sk
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c_ref ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE td.t_meal_time = 'dinner'
      AND c_ref.c_preferred_cust_flag = 'Y'
      AND ca_ref.ca_suite_number LIKE 'Suite %'
      AND wr.wr_return_amt > 100
),
preferred_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
),
last_name_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    WHERE c.c_last_name IN ('Grimes', 'Moore')
),
common_customers AS (
    SELECT pc.c_customer_sk
    FROM preferred_customers pc
    INTERSECT
    SELECT lc.c_customer_sk
    FROM last_name_customers lc
),
agg_by_meal AS (
    SELECT
        c.c_customer_sk,
        td.t_meal_time,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE td.t_meal_time IN ('dinner', 'lunch')
      AND c.c_customer_sk IN (SELECT c_customer_sk FROM common_customers)
    GROUP BY c.c_customer_sk, td.t_meal_time
),
union_returns AS (
    SELECT c_customer_sk, total_return_amt
    FROM agg_by_meal
    WHERE t_meal_time = 'dinner'
    UNION
    SELECT c_customer_sk, total_return_amt
    FROM agg_by_meal
    WHERE t_meal_time = 'lunch'
),
final AS (
    SELECT
        ur.c_customer_sk,
        ur.total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY ur.c_customer_sk ORDER BY ur.total_return_amt DESC) AS rn,
        (SELECT SUM(wr2.wr_return_amt)
         FROM web_returns wr2
         WHERE wr2.wr_refunded_customer_sk = ur.c_customer_sk) AS customer_total_refund
    FROM union_returns ur
    WHERE ur.total_return_amt > 50
)
SELECT
    f.c_customer_sk,
    f.total_return_amt,
    f.rn,
    f.customer_total_refund
FROM final f
ORDER BY f.total_return_amt DESC
OFFSET 10
LIMIT 100
