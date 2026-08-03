WITH base_join AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_return_amount,
        cr.cr_store_credit,
        cr.cr_fee,
        cr.cr_return_quantity,
        td.t_time,
        td.t_meal_time,
        td.t_shift,
        cust.c_customer_id,
        cust.c_preferred_cust_flag,
        wp.wp_type,
        ca.ca_state
    FROM catalog_returns cr
    INNER JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    INNER JOIN customer cust
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    FULL OUTER JOIN web_page wp
        ON wp.wp_customer_sk = cust.c_customer_sk
    LEFT JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE td.t_time BETWEEN 0 AND 23
      AND td.t_meal_time IN ('lunch', 'dinner')
      AND cust.c_preferred_cust_flag = 'Y'
      AND cr.cr_store_credit > 10
      AND cr.cr_fee BETWEEN 20 AND 60
      AND wp.wp_type IS NOT NULL
),
agg_per_customer AS (
    SELECT
        cust.c_customer_id,
        td.t_meal_time,
        wp.wp_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_store_credit) AS total_store_credit,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_fee) AS avg_fee
    FROM base_join bj
    INNER JOIN catalog_returns cr
        ON bj.cr_returned_date_sk = cr.cr_returned_date_sk
        AND bj.cr_returned_time_sk = cr.cr_returned_time_sk
    INNER JOIN time_dim td
        ON bj.t_time = td.t_time
    INNER JOIN customer cust
        ON bj.c_customer_id = cust.c_customer_id
    INNER JOIN web_page wp
        ON bj.wp_type = wp.wp_type
    GROUP BY cust.c_customer_id, td.t_meal_time, wp.wp_type
),
final_agg AS (
    SELECT
        t_meal_time,
        wp_type,
        AVG(total_return_amount) AS avg_total_return,
        SUM(return_cnt) AS total_returns,
        ROW_NUMBER() OVER (ORDER BY AVG(total_return_amount) DESC) AS rn
    FROM agg_per_customer
    GROUP BY t_meal_time, wp_type
    HAVING AVG(total_return_amount) > 100
)
SELECT
    t_meal_time,
    wp_type,
    avg_total_return,
    total_returns,
    rn
FROM final_agg
ORDER BY avg_total_return DESC
LIMIT 100
