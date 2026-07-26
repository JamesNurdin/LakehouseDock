WITH promo_effectiveness AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_response_target,
        ca.ca_state,
        AVG(td.t_hour) AS avg_sale_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity
    FROM promotion p
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk, p.p_response_target, ca.ca_state
)
SELECT
    p_promo_sk,
    p_promo_name,
    ca_state,
    avg_sale_hour,
    total_sales,
    total_quantity,
    p_response_target,
    CASE WHEN p_response_target > 0 THEN total_sales / p_response_target ELSE NULL END AS response_rate,
    LAG(CASE WHEN p_response_target > 0 THEN total_sales / p_response_target ELSE NULL END) OVER (ORDER BY p_start_date_sk) AS previous_response_rate,
    (CASE WHEN p_response_target > 0 THEN total_sales / p_response_target ELSE NULL END) -
        LAG(CASE WHEN p_response_target > 0 THEN total_sales / p_response_target ELSE NULL END) OVER (ORDER BY p_start_date_sk) AS response_rate_change
FROM promo_effectiveness
WHERE p_response_target IS NOT NULL
ORDER BY p_start_date_sk
