WITH
    filtered_time AS (
        SELECT t_time_sk
        FROM time_dim
        WHERE t_hour BETWEEN 9 AND 17
          AND t_meal_time = 'Lunch'
    ),
    filtered_demo AS (
        SELECT cd_demo_sk
        FROM customer_demographics
        WHERE cd_dep_college_count >= 2
          AND cd_credit_rating = 'Excellent'
    ),
    filtered_store AS (
        SELECT s_store_sk
        FROM store
        WHERE s_state = 'CA'
          AND s_number_employees > 150
    ),
    filtered_customer AS (
        SELECT c_customer_sk
        FROM customer
        WHERE c_preferred_cust_flag = 'Y'
          AND c_birth_year BETWEEN 1960 AND 1980
    ),
    -- intersect customers that are preferred and have the selected demographic
    preferred_demo_customers AS (
        SELECT fc.c_customer_sk
        FROM filtered_customer fc
        INTERSECT
        SELECT cs.cs_bill_customer_sk
        FROM catalog_sales cs
        WHERE cs.cs_bill_cdemo_sk IN (SELECT cd_demo_sk FROM filtered_demo)
    ),
    -- union of three fact‑like sources
    union_facts AS (
        SELECT
            ss.ss_sold_time_sk AS time_sk,
            ss.ss_customer_sk AS customer_sk,
            ss.ss_cdemo_sk AS cdemo_sk,
            ss.ss_store_sk AS store_sk,
            ss.ss_ext_sales_price AS amount,
            'store' AS src
        FROM store_sales ss
        JOIN filtered_time ft ON ss.ss_sold_time_sk = ft.t_time_sk
        JOIN filtered_store fs ON ss.ss_store_sk = fs.s_store_sk
        JOIN filtered_demo fd ON ss.ss_cdemo_sk = fd.cd_demo_sk
        WHERE ss.ss_quantity > 1
          AND ss.ss_ext_sales_price > 200
          AND ss.ss_customer_sk IN (SELECT c_customer_sk FROM preferred_demo_customers)
        UNION
        SELECT
            cs.cs_sold_time_sk AS time_sk,
            cs.cs_bill_customer_sk AS customer_sk,
            cs.cs_bill_cdemo_sk AS cdemo_sk,
            NULL AS store_sk,
            cs.cs_ext_sales_price AS amount,
            'catalog' AS src
        FROM catalog_sales cs
        JOIN filtered_time ft ON cs.cs_sold_time_sk = ft.t_time_sk
        JOIN filtered_demo fd ON cs.cs_bill_cdemo_sk = fd.cd_demo_sk
        WHERE cs.cs_quantity > 1
          AND cs.cs_ext_sales_price > 200
        UNION
        SELECT
            wr.wr_returned_time_sk AS time_sk,
            wr.wr_refunded_customer_sk AS customer_sk,
            wr.wr_refunded_cdemo_sk AS cdemo_sk,
            NULL AS store_sk,
            -wr.wr_return_amt AS amount,
            'web_return' AS src
        FROM web_returns wr
        JOIN filtered_time ft ON wr.wr_returned_time_sk = ft.t_time_sk
        JOIN filtered_demo fd ON wr.wr_refunded_cdemo_sk = fd.cd_demo_sk
        WHERE wr.wr_return_quantity > 0
          AND wr.wr_return_amt > 50
    ),
    aggregated AS (
        SELECT
            time_sk,
            customer_sk,
            SUM(amount) AS total_amount,
            COUNT(DISTINCT src) AS source_count
        FROM union_facts
        GROUP BY time_sk, customer_sk
    ),
    final AS (
        SELECT
            a.time_sk,
            td.t_hour,
            td.t_meal_time,
            a.customer_sk,
            c.c_first_name,
            c.c_last_name,
            a.total_amount,
            a.source_count,
            a.total_amount / NULLIF(a.source_count, 0) AS avg_amount_per_source
        FROM aggregated a
        JOIN time_dim td ON a.time_sk = td.t_time_sk
        JOIN customer c ON a.customer_sk = c.c_customer_sk
        WHERE a.total_amount > 1000
          AND td.t_hour BETWEEN 10 AND 15
          AND c.c_birth_month = 7
          AND c.c_birth_day = 15
    )
SELECT
    time_sk,
    t_hour,
    t_meal_time,
    customer_sk,
    c_first_name,
    c_last_name,
    total_amount,
    source_count,
    avg_amount_per_source
FROM final
ORDER BY total_amount DESC
LIMIT 100
