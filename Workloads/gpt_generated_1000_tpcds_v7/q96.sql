WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        s.s_store_name,
        sr.sr_return_amt,
        cr.cr_refunded_cash,
        sm.sm_carrier,
        ws.ws_web_site_sk,
        wsite.web_name,
        c_refund.c_customer_sk AS refunded_customer_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN tpcds.customer c_refund
        ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451400 AND 2451500
)
SELECT
    s_store_name,
    sm_carrier,
    cd_gender,
    web_name,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_profit,
    SUM(sr_return_amt) AS total_store_return_amount,
    SUM(cr_refunded_cash) AS total_catalog_refund_cash,
    AVG(ss_ext_sales_price) AS avg_sales_price
FROM base
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.catalog_returns cr2
    WHERE cr2.cr_refunded_customer_sk = base.c_customer_sk
      AND cr2.cr_fee > 100
)
GROUP BY
    s_store_name,
    sm_carrier,
    cd_gender,
    web_name
ORDER BY total_net_paid DESC
LIMIT 100
