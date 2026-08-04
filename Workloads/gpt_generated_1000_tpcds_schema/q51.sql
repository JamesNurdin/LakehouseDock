WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
sub_a AS (
    SELECT
        c.c_customer_id AS customer_id,
        ca.ca_city AS city,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales
    FROM sampled_sales ss
    RIGHT OUTER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ss.ss_net_paid_inc_tax > 500
      AND ca.ca_state = 'CA'
    GROUP BY c.c_customer_id, ca.ca_city
),
sub_b AS (
    SELECT
        c.c_customer_id AS customer_id,
        ca.ca_city AS city,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales
    FROM sampled_sales ss
    RIGHT OUTER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN customer c
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ss.ss_list_price BETWEEN 20 AND 60
      AND ca.ca_zip LIKE '9%'
    GROUP BY c.c_customer_id, ca.ca_city
),
unioned AS (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num,
    customer_id,
    city,
    total_sales
FROM unioned
ORDER BY row_num
LIMIT 100
