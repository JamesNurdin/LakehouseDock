WITH filtered_afternoon AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        td.t_sub_shift,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        COUNT(*) AS purchase_cnt
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT t.t_sub_shift
        FROM time_dim t
        WHERE t.t_time_sk = ss.ss_sold_time_sk
    ) AS td
    WHERE td.t_sub_shift = 'afternoon'
      AND c.c_birth_month IN (12, 9, 6)
      AND ss.ss_ext_list_price > 200
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, td.t_sub_shift
),
filtered_evening AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        td.t_sub_shift,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        COUNT(*) AS purchase_cnt
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT t.t_sub_shift
        FROM time_dim t
        WHERE t.t_time_sk = ss.ss_sold_time_sk
    ) AS td
    WHERE td.t_sub_shift = 'evening'
      AND c.c_birth_month IN (4, 1)
      AND ss.ss_ext_list_price > 500
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, td.t_sub_shift
)
SELECT DISTINCT *
FROM (
    SELECT 'Afternoon' AS shift_category,
           c_customer_id,
           c_first_name,
           c_last_name,
           total_spent,
           purchase_cnt
    FROM filtered_afternoon
    UNION ALL
    SELECT 'Evening' AS shift_category,
           c_customer_id,
           c_first_name,
           c_last_name,
           total_spent,
           purchase_cnt
    FROM filtered_evening
) u
ORDER BY total_spent DESC
LIMIT 100
