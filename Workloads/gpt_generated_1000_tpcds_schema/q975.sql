WITH union_customers AS (
    SELECT c.c_customer_id AS customer_id
    FROM call_center cc
    FULL OUTER JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
      AND cs.cs_ext_sales_price > (
            SELECT MAX(ss_ext_sales_price)
            FROM store_sales ss
            WHERE ss.ss_sold_date_sk = d.d_date_sk
        )
    UNION
    SELECT c.c_customer_id AS customer_id
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
),
return_customers AS (
    SELECT c.c_customer_id AS customer_id
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
),
low_profit_customers AS (
    SELECT cust_id
    FROM (
        SELECT c.c_customer_id AS cust_id,
               COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) AS total_profit
        FROM customer c
        LEFT JOIN catalog_sales cs
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        LEFT JOIN store_sales ss
            ON ss.ss_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_id
    ) t
    WHERE total_profit < (
        SELECT AVG(cs_net_profit)
        FROM catalog_sales
    )
)
SELECT customer_id
FROM union_customers
INTERSECT
SELECT customer_id
FROM return_customers
EXCEPT
SELECT cust_id AS customer_id
FROM low_profit_customers
ORDER BY customer_id
LIMIT 100
