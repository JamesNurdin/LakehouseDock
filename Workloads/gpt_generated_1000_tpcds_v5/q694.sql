WITH joined_sales AS (
    SELECT
        s.ss_customer_sk,
        s.ss_net_paid,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        h.hd_vehicle_count
    FROM store_sales s
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics h ON s.ss_hdemo_sk = h.hd_demo_sk
)
SELECT
    js.c_customer_id,
    js.c_first_name,
    js.c_last_name,
    SUM(js.ss_net_paid) AS total_net_paid,
    COUNT(*) AS transaction_cnt,
    'Mexico_Vehicles_2plus' AS group_label
FROM joined_sales js
WHERE js.c_birth_country = 'MEXICO'
  AND js.hd_vehicle_count >= 2
GROUP BY js.c_customer_id, js.c_first_name, js.c_last_name

UNION ALL

SELECT
    js.c_customer_id,
    js.c_first_name,
    js.c_last_name,
    SUM(js.ss_net_paid) AS total_net_paid,
    COUNT(*) AS transaction_cnt,
    'Jordan_Vehicles_1' AS group_label
FROM joined_sales js
WHERE js.c_birth_country = 'JORDAN'
  AND js.hd_vehicle_count = 1
GROUP BY js.c_customer_id, js.c_first_name, js.c_last_name

LIMIT 100
