WITH store_customer_sales AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        MIN(td.t_shift) AS first_shift
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE REGEXP_LIKE(c.c_first_name, '^J')
      AND td.t_shift = 'first'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ss.ss_net_paid) > 1000
       AND NOT EXISTS (
           SELECT 1 FROM store_returns sr
           WHERE sr.sr_customer_sk = c.c_customer_sk
       )
),
web_customer_sales AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        MIN(td.t_shift) AS first_shift
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE REGEXP_LIKE(c.c_last_name, 'son$')
      AND ws.ws_net_paid_inc_tax > 200
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_net_paid_inc_tax) > 1000
)
SELECT
    c_customer_sk,
    full_name,
    total_net_paid,
    first_shift
FROM (
    SELECT c_customer_sk, full_name, total_net_paid, first_shift FROM store_customer_sales
    UNION ALL
    SELECT c_customer_sk, full_name, total_net_paid, first_shift FROM web_customer_sales
) combined
ORDER BY total_net_paid DESC
LIMIT 100
