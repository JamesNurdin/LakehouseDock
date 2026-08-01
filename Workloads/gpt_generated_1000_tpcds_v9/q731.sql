WITH
    filtered_sales AS (
        SELECT
            c.c_customer_sk,
            c.c_birth_country,
            c.c_salutation,
            c.c_current_hdemo_sk,
            ss.ss_sold_date_sk,
            ss.ss_quantity,
            ss.ss_wholesale_cost,
            ss.ss_ext_sales_price,
            ss.ss_coupon_amt,
            ss.ss_net_paid,
            ss.ss_net_profit
        FROM customer c
        JOIN store_sales ss
            ON ss.ss_customer_sk = c.c_customer_sk
        WHERE c.c_birth_country = 'SWITZERLAND'
          AND c.c_salutation = 'Ms.'
          AND ss.ss_wholesale_cost > 50
          AND ss.ss_ext_sales_price > 1000
    ),
    eligible_customers AS (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE c.c_birth_country = 'SWITZERLAND'
        INTERSECT
        SELECT ss.ss_customer_sk
        FROM store_sales ss
        WHERE ss.ss_wholesale_cost > 55
    ),
    unioned_sales AS (
        SELECT
            fs.c_customer_sk,
            fs.c_birth_country,
            fs.c_salutation,
            fs.c_current_hdemo_sk,
            fs.ss_sold_date_sk,
            fs.ss_net_paid,
            fs.ss_coupon_amt,
            CASE WHEN fs.ss_coupon_amt > 1000 THEN 'High' ELSE 'Low' END AS coupon_category,
            (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS global_avg_net_paid,
            SUM(fs.ss_net_paid) OVER (PARTITION BY fs.c_birth_country ORDER BY fs.ss_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
            l.max_net_paid_for_customer
        FROM filtered_sales fs
        LEFT JOIN LATERAL (
            SELECT MAX(ss2.ss_net_paid) AS max_net_paid_for_customer
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = fs.c_customer_sk
        ) AS l ON TRUE
        WHERE fs.c_current_hdemo_sk = 4470
          AND fs.c_customer_sk IN (SELECT c_customer_sk FROM eligible_customers)
        UNION DISTINCT
        SELECT
            fs.c_customer_sk,
            fs.c_birth_country,
            fs.c_salutation,
            fs.c_current_hdemo_sk,
            fs.ss_sold_date_sk,
            fs.ss_net_paid,
            fs.ss_coupon_amt,
            CASE WHEN fs.ss_coupon_amt > 1000 THEN 'High' ELSE 'Low' END AS coupon_category,
            (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS global_avg_net_paid,
            SUM(fs.ss_net_paid) OVER (PARTITION BY fs.c_birth_country ORDER BY fs.ss_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
            l.max_net_paid_for_customer
        FROM filtered_sales fs
        LEFT JOIN LATERAL (
            SELECT MAX(ss2.ss_net_paid) AS max_net_paid_for_customer
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = fs.c_customer_sk
        ) AS l ON TRUE
        WHERE fs.c_current_hdemo_sk = 6374
          AND fs.c_customer_sk IN (SELECT c_customer_sk FROM eligible_customers)
    )
SELECT
    us.c_birth_country,
    us.c_salutation,
    us.c_current_hdemo_sk,
    COUNT(*) AS transaction_count,
    SUM(us.ss_net_paid) AS total_net_paid,
    AVG(us.ss_net_paid) AS avg_net_paid,
    MIN(us.ss_net_paid) AS min_net_paid,
    MAX(us.ss_net_paid) AS max_net_paid,
    SUM(CASE WHEN us.coupon_category = 'High' THEN us.ss_net_paid ELSE 0 END) AS high_coupon_net_paid,
    AVG(us.cumulative_net_paid) AS avg_cumulative_net_paid,
    MAX(us.global_avg_net_paid) AS global_avg_net_paid_ref,
    MAX(us.max_net_paid_for_customer) AS max_customer_net_paid
FROM unioned_sales us
WHERE us.ss_net_paid > 2000
  AND us.c_birth_country IN ('SWITZERLAND', 'PHILIPPINES')
GROUP BY GROUPING SETS (
    (us.c_birth_country, us.c_salutation, us.c_current_hdemo_sk),
    (us.c_birth_country, us.c_salutation),
    (us.c_birth_country),
    ()
)
HAVING SUM(us.ss_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
