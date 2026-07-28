/*
Goal: Compare total net paid sales per store with total refunded cash per customer for the year 2001, and include the overall average sales price as a reference metric.
*/
WITH avg_price AS (
    SELECT avg(ss.ss_sales_price) AS avg_price_2001
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT entity_name,
       total_amount,
       avg_price_2001
FROM (
    SELECT s.s_store_name AS entity_name,
           sum(ss.ss_net_paid) AS total_amount,
           (SELECT avg_price_2001 FROM avg_price) AS avg_price_2001
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_name

    UNION ALL

    SELECT concat(c.c_first_name, ' ', c.c_last_name) AS entity_name,
           sum(wr.wr_refunded_cash) AS total_amount,
           (SELECT avg_price_2001 FROM avg_price) AS avg_price_2001
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_first_name, c.c_last_name
) t
LIMIT 100
