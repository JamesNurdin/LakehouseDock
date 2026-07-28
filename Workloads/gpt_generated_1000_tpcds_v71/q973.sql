/*
Goal: Analyze sales performance by promotion, return reason, call‑center, and web page, enriched with customer demographic and income information, while excluding sales that also appear as web returns. The query aggregates revenue and return metrics, categorises store‑credit levels, applies realistic filters, and returns the top rows.
*/
WITH sales_time AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_ticket_number,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        td.t_hour,
        td.t_am_pm
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
)
SELECT
    p.p_promo_name,
    r.r_reason_desc,
    cc.cc_name,
    wp.wp_url,
    ib.ib_lower_bound,
    CASE WHEN sr.sr_store_credit > 500 THEN 'High' ELSE 'Low' END AS credit_category,
    SUM(st.ss_net_paid)               AS total_net_paid,
    SUM(sr.sr_return_amt)             AS total_return_amount,
    AVG(sr.sr_store_credit)           AS avg_store_credit,
    COUNT(DISTINCT st.ss_customer_sk) AS distinct_customers
FROM sales_time st
JOIN tpcds.promotion p
    ON st.ss_promo_sk = p.p_promo_sk
JOIN tpcds.customer_demographics cd
    ON st.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON st.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.customer_address ca
    ON st.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = st.ss_ticket_number
JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_time_sk = st.ss_sold_time_sk
JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.web_returns wr
    ON wr.wr_returned_time_sk = st.ss_sold_time_sk
JOIN tpcds.web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    p.p_channel_radio = 'N'
    AND sr.sr_store_credit > 200
    AND cc.cc_state = 'CA'
    AND NOT EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_order_number = st.ss_ticket_number
    )
GROUP BY
    p.p_promo_name,
    r.r_reason_desc,
    cc.cc_name,
    wp.wp_url,
    ib.ib_lower_bound,
    CASE WHEN sr.sr_store_credit > 500 THEN 'High' ELSE 'Low' END
HAVING
    SUM(st.ss_net_paid) > 10000
ORDER BY
    total_net_paid DESC
LIMIT 100
