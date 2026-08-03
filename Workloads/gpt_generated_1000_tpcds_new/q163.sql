WITH ss_agg AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        td.t_hour AS hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        td.t_hour
)
SELECT
    p.p_promo_name,
    r.r_reason_desc,
    ssa.hour,
    c.c_customer_id,
    ca.ca_state,
    wp.wp_type,
    cd.cd_gender,
    SUM(ssa.total_net_paid) AS total_sales,
    SUM(ssa.total_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount
FROM ss_agg ssa
JOIN customer c
    ON ssa.ss_customer_sk = c.c_customer_sk
JOIN promotion p
    ON ssa.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE
    ssa.hour BETWEEN 8 AND 20
    AND p.p_discount_active = 'Y'
    AND c.c_preferred_cust_flag = 'Y'
    AND ca.ca_state = 'CA'
    AND r.r_reason_desc LIKE '%size%'
    AND cr.cr_return_amount > 1000
GROUP BY CUBE (
    p.p_promo_name,
    r.r_reason_desc,
    ssa.hour,
    c.c_customer_id,
    ca.ca_state,
    wp.wp_type,
    cd.cd_gender
)
ORDER BY total_sales DESC
