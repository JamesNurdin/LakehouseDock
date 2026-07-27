WITH sales_a AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax
    FROM
        store_sales AS ss
        JOIN customer AS c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        c.c_last_review_date > 2452570
        AND ss.ss_sold_date_sk BETWEEN 2452000 AND 2452100
    GROUP BY
        c.c_customer_id
    HAVING
        SUM(ss.ss_net_paid_inc_tax) > 5000
),
sales_b AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax
    FROM
        store_sales AS ss
        JOIN customer AS c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
        AND ss.ss_ext_list_price > 5000
    GROUP BY
        c.c_customer_id
    HAVING
        SUM(ss.ss_net_paid_inc_tax) BETWEEN 1000 AND 5000
)
SELECT DISTINCT
    customer_id,
    total_net_paid_inc_tax
FROM (
    SELECT c_customer_id AS customer_id, total_net_paid_inc_tax FROM sales_a
    UNION ALL
    SELECT c_customer_id AS customer_id, total_net_paid_inc_tax FROM sales_b
) AS combined
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
