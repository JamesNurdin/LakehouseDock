WITH filtered_sales AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_ext_discount_amt,
        ws.ws_order_number,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_current_cdemo_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_net_paid_inc_tax > 1000
      AND ws.ws_net_paid_inc_tax < 20000
      AND ws.ws_ship_cdemo_sk IN (293885, 215362, 601676)
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND c.c_current_cdemo_sk NOT IN (75107)
      AND c.c_birth_year BETWEEN 1950 AND 1970
)
SELECT
    customer_sk,
    c_first_name,
    c_last_name,
    total_net_paid,
    order_cnt,
    avg_discount,
    RANK() OVER (ORDER BY total_net_paid DESC) AS spend_rank,
    ROW_NUMBER() OVER (PARTITION BY c_birth_year ORDER BY total_net_paid DESC) AS rn_by_birth_year
FROM (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        MAX(c_first_name) AS c_first_name,
        MAX(c_last_name) AS c_last_name,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_cnt,
        AVG(ws_ext_discount_amt) AS avg_discount,
        c_birth_year
    FROM filtered_sales
    GROUP BY ws_bill_customer_sk, c_birth_year
) agg
WHERE total_net_paid > (
    SELECT AVG(customer_total)
    FROM (
        SELECT SUM(ws_net_paid_inc_tax) AS customer_total
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ) inner_sub
)
ORDER BY spend_rank
LIMIT 50
