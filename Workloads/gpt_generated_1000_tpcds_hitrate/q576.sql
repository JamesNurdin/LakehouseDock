WITH cr_agg AS (
    SELECT
        cr_reason_sk,
        cr_ship_mode_sk,
        cr_returned_time_sk,
        cr_refunded_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS distinct_return_orders,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND cr_return_amount > 50
      AND cr_return_quantity >= 1
    GROUP BY cr_reason_sk, cr_ship_mode_sk, cr_returned_time_sk, cr_refunded_customer_sk
)
SELECT
    r.r_reason_desc,
    sm.sm_type,
    td.t_meal_time,
    SUM(cr.total_return_amount) AS sum_return_amount,
    SUM(ss.ss_ext_sales_price) AS sum_sales_amount,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_return_customers,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    CASE WHEN SUM(cr.total_return_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_level
FROM cr_agg cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    AND ss.ss_sold_time_sk = td.t_time_sk
WHERE td.t_meal_time = 'dinner'
  AND r.r_reason_desc = 'Customer not satisfied'
  AND sm.sm_type = 'Air'
  AND c.c_birth_year >= 1960
  AND ss.ss_ext_sales_price > 0
  AND ss.ss_quantity > 0
GROUP BY CUBE (r.r_reason_desc, sm.sm_type, td.t_meal_time)
HAVING SUM(cr.total_return_amount) IS NOT NULL

UNION DISTINCT

SELECT
    r.r_reason_desc,
    sm.sm_type,
    td.t_meal_time,
    SUM(cr.total_return_amount) AS sum_return_amount,
    SUM(ss.ss_ext_sales_price) AS sum_sales_amount,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_return_customers,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    CASE WHEN SUM(cr.total_return_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_level
FROM cr_agg cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    AND ss.ss_sold_time_sk = td.t_time_sk
WHERE td.t_meal_time = 'lunch'
  AND r.r_reason_desc = 'Promotional return'
  AND sm.sm_type = 'Ground'
  AND c.c_birth_year < 1960
  AND ss.ss_ext_sales_price > 0
  AND ss.ss_quantity > 0
GROUP BY CUBE (r.r_reason_desc, sm.sm_type, td.t_meal_time)
HAVING SUM(cr.total_return_amount) IS NOT NULL
ORDER BY sum_return_amount DESC
LIMIT 100
