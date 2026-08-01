WITH
    -- Customers with specific demographic filters
    cust_set_a AS (
        SELECT c_customer_sk
        FROM tpcds.customer
        WHERE c_salutation = 'Mrs.'
          AND c_birth_year = 1975
    ),
    cust_set_b AS (
        SELECT c_customer_sk
        FROM tpcds.customer
        WHERE c_preferred_cust_flag = 'Y'
          AND c_birth_month = 5
    ),
    -- Customers in A but not in B
    cust_except AS (
        SELECT c_customer_sk FROM cust_set_a
        EXCEPT
        SELECT c_customer_sk FROM cust_set_b
    ),
    -- Sales with high list price and a specific sold time
    sales_set_c AS (
        SELECT ss_customer_sk
        FROM tpcds.store_sales
        WHERE ss_list_price > 60
          AND ss_sold_time_sk = 35137
    ),
    -- Sales with quantity and tax constraints
    sales_set_d AS (
        SELECT ss_customer_sk
        FROM tpcds.store_sales
        WHERE ss_quantity >= 2
          AND ss_ext_tax < 100
    ),
    -- Customers appearing in both sales sets
    sales_intersect AS (
        SELECT ss_customer_sk FROM sales_set_c
        INTERSECT
        SELECT ss_customer_sk FROM sales_set_d
    ),
    -- Full outer join to keep all customers and all sales rows
    full_cust_sales AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            ss.ss_sold_date_sk,
            ss.ss_sales_price,
            ss.ss_net_paid
        FROM tpcds.customer c
        FULL OUTER JOIN tpcds.store_sales ss
            ON c.c_customer_sk = ss.ss_customer_sk
    ),
    -- Main analytical query
    final_result AS (
        SELECT
            f.c_customer_sk,
            f.c_first_name,
            f.c_last_name,
            f.ss_sold_date_sk,
            COUNT(*) AS trans_cnt,
            SUM(f.ss_sales_price) AS total_sales,
            AVG(f.ss_net_paid) AS avg_net_paid,
            MIN(f.ss_sales_price) AS min_sales,
            MAX(f.ss_sales_price) AS max_sales,
            (
                SELECT SUM(ss2.ss_net_profit)
                FROM tpcds.store_sales ss2
                WHERE ss2.ss_customer_sk = f.c_customer_sk
            ) AS customer_total_profit
        FROM full_cust_sales f
        LEFT JOIN cust_except ce
            ON f.c_customer_sk = ce.c_customer_sk
        LEFT JOIN sales_intersect si
            ON f.c_customer_sk = si.ss_customer_sk
        WHERE ce.c_customer_sk IS NOT NULL               -- customers in EXCEPT set
          AND si.ss_customer_sk IS NOT NULL              -- customers in INTERSECT set
          AND f.c_first_name IS NOT NULL                 -- non‑null first name
          AND f.ss_sales_price > 20                      -- price filter
        GROUP BY GROUPING SETS (
            (f.c_customer_sk, f.c_first_name, f.c_last_name, f.ss_sold_date_sk),
            (f.c_customer_sk, f.c_first_name, f.c_last_name),
            (f.c_customer_sk)
        )
    )
SELECT *
FROM final_result
ORDER BY c_customer_sk
LIMIT 100
