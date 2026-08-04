WITH
    scalar_sub AS (
        SELECT max(ss_net_paid) AS max_net
        FROM store_sales ss
    ),
    union_set AS (
        SELECT c.c_customer_id,
               cs.cs_net_paid_inc_tax AS total_paid,
               CAST('catalog' AS varchar) AS channel
        FROM catalog_sales cs
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        WHERE td.t_time BETWEEN 2 AND 14
          AND cs.cs_net_paid_inc_tax > (SELECT max_net FROM scalar_sub)
        UNION
        SELECT c.c_customer_id,
               ss.ss_net_paid AS total_paid,
               CAST('store' AS varchar) AS channel
        FROM store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE td.t_time BETWEEN 2 AND 14
          AND ss.ss_net_paid > (SELECT max_net FROM scalar_sub)
    ),
    returns_set AS (
        SELECT c.c_customer_id,
               CAST(NULL AS decimal(7,2)) AS total_paid,
               CAST(NULL AS varchar) AS channel
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        WHERE td.t_time BETWEEN 2 AND 14
    )
SELECT *
FROM union_set
EXCEPT
SELECT *
FROM returns_set
ORDER BY total_paid DESC
LIMIT 100
