WITH filtered_data AS (
    SELECT
        cd.cd_gender,
        ca.ca_state,
        sm.sm_code,
        p.p_promo_name,
        t.channel,
        ss.ss_net_paid,
        cr.cr_return_amount,
        ss.ss_ticket_number,
        ss.ss_ext_tax,
        ss.ss_ext_sales_price
    FROM
        store_sales ss
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN catalog_returns cr ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        CROSS JOIN UNNEST(array[p.p_channel_dmail, p.p_channel_email, p.p_channel_catalog]) AS t(channel)
    WHERE
        cr.cr_reason_sk IN (12, 15, 27)
        AND sm.sm_code = 'AIR'
        AND ca.ca_state = 'CA'
        AND cd.cd_gender = 'F'
        AND ss.ss_ext_sales_price > 1000
)
SELECT
    cd_gender,
    ca_state,
    sm_code,
    p_promo_name,
    channel,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT ss_ticket_number) AS order_cnt,
    MIN(ss_ext_tax) AS min_tax,
    MAX(ss_ext_sales_price) AS max_sales
FROM
    filtered_data
GROUP BY
    cd_gender,
    ca_state,
    sm_code,
    p_promo_name,
    channel
ORDER BY
    total_net_paid DESC
LIMIT 100
