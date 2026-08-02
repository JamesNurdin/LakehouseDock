WITH
    -- Filtered join of customers and sales with selective predicates
    filtered_data AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            c.c_salutation,
            c.c_first_sales_date_sk,
            ss.ss_sold_date_sk,
            ss.ss_list_price,
            ss.ss_ext_sales_price,
            ss.ss_net_profit,
            ss.ss_item_sk
        FROM tpcds.customer c
        JOIN tpcds.store_sales ss
            ON ss.ss_customer_sk = c.c_customer_sk
        WHERE c.c_salutation IN ('Dr.', 'Ms.', 'Mrs.')
          AND c.c_first_sales_date_sk BETWEEN 2450000 AND 2452000
          AND ss.ss_list_price > 20.0
    ),
    -- Customers that have purchased high‑price items
    customers_by_price AS (
        SELECT DISTINCT c_customer_sk
        FROM filtered_data
        WHERE ss_list_price > 50.0
    ),
    -- Customers that have generated positive profit
    customers_by_profit AS (
        SELECT DISTINCT c_customer_sk
        FROM filtered_data
        WHERE ss_net_profit > 0
    ),
    -- Intersection of the two sets gives customers satisfying both conditions
    common_customers AS (
        SELECT c_customer_sk FROM customers_by_price
        INTERSECT
        SELECT c_customer_sk FROM customers_by_profit
    ),
    -- Aggregation per customer (measures + CASE expression)
    customer_agg AS (
        SELECT
            c.c_customer_id,
            c.c_salutation,
            c.c_customer_sk,
            SUM(fd.ss_ext_sales_price) AS total_sales,
            AVG(fd.ss_list_price) AS avg_list_price,
            COUNT(DISTINCT fd.ss_item_sk) AS distinct_items,
            CASE WHEN SUM(fd.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
        FROM tpcds.customer c
        JOIN filtered_data fd
            ON fd.c_customer_sk = c.c_customer_sk
        WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM common_customers)
        GROUP BY c.c_customer_id, c.c_salutation, c.c_customer_sk
        HAVING COUNT(*) >= 5
    ),
    -- Window function to rank customers within each salutation by total sales
    ranked_customers AS (
        SELECT
            c_customer_id,
            c_salutation,
            total_sales,
            avg_list_price,
            distinct_items,
            profit_flag,
            ROW_NUMBER() OVER (PARTITION BY c_salutation ORDER BY total_sales DESC) AS salutation_rank
        FROM customer_agg
    )
SELECT
    c_customer_id,
    c_salutation,
    total_sales,
    avg_list_price,
    distinct_items,
    profit_flag,
    salutation_rank
FROM ranked_customers
WHERE salutation_rank <= 10
UNION
SELECT
    c_customer_id,
    c_salutation,
    total_sales,
    avg_list_price,
    distinct_items,
    profit_flag,
    salutation_rank
FROM ranked_customers
WHERE salutation_rank > 10 AND salutation_rank <= 20
ORDER BY total_sales DESC, c_customer_id
LIMIT 100
