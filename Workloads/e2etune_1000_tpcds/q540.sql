WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_salutation,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM customer c
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1967
      AND c.c_salutation IN ('Mr.', 'Mrs.')
      AND ws.ws_sold_date_sk BETWEEN 2449500 AND 2450000
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_salutation
)
SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_birth_year,
    cs.c_salutation,
    cs.total_net_paid,
    cs.total_net_profit,
    cs.total_discount,
    cs.order_cnt,
    cs.avg_quantity,
    RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
FROM customer_sales cs
WHERE cs.total_net_profit > 500
ORDER BY cs.total_net_profit DESC
LIMIT 50
