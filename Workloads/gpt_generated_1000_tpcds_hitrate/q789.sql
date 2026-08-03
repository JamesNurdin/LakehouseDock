WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_mode_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_amount,
        cr.cr_fee,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        sm.sm_carrier,
        td.t_shift,
        ARRAY[sm.sm_carrier] AS arr_carrier
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
      AND sm.sm_carrier = 'AIRBORNE'
      AND cr.cr_fee > 20
      AND cs.cs_quantity >= 2
      AND ca.ca_state = 'CA'
),
joined AS (
    SELECT
        b.cs_sold_date_sk,
        b.cs_bill_customer_sk,
        b.cs_quantity,
        b.cs_net_paid,
        b.cr_return_amount,
        b.arr_carrier,
        b.c_first_name,
        b.c_last_name
    FROM base b
),
windowed AS (
    SELECT
        *,
        SUM(cs_net_paid) OVER (PARTITION BY cs_bill_customer_sk ORDER BY cs_sold_date_sk ROWS UNBOUNDED PRECEDING) AS running_net_paid,
        LAG(cs_quantity) OVER (PARTITION BY cs_bill_customer_sk ORDER BY cs_sold_date_sk) AS prev_quantity
    FROM joined
)
SELECT
    w.cs_bill_customer_sk,
    w.c_first_name,
    w.c_last_name,
    SUM(w.cs_net_paid) AS total_net_paid,
    AVG(w.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT w.cs_sold_date_sk) AS distinct_sale_days,
    MIN(w.cs_quantity) AS min_quantity,
    MAX(w.cs_quantity) AS max_quantity,
    MAX(w.running_net_paid) AS max_running_net_paid,
    MAX(w.prev_quantity) AS max_previous_quantity,
    u.carrier,
    (SELECT MAX(cr_fee) FROM catalog_returns WHERE cr_fee > 0) AS max_fee_overall
FROM windowed w
CROSS JOIN UNNEST(w.arr_carrier) AS u(carrier)
GROUP BY w.cs_bill_customer_sk, w.c_first_name, w.c_last_name, u.carrier
ORDER BY total_net_paid DESC
LIMIT 100
