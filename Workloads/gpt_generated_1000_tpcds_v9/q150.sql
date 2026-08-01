WITH cr_join AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cc.cc_call_center_id,
        cc.cc_zip,
        cc.cc_country,
        cc.cc_rec_start_date,
        cc.cc_rec_end_date,
        cp.cp_catalog_page_id,
        cp.cp_department,
        r.r_reason_id,
        r.r_reason_desc,
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_country = 'United States'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_end_date <= DATE '2002-12-31'
      AND cp.cp_department = 'Electronics'
),
ws_join AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_tax,
        ws.ws_ship_mode_sk,
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_net_paid_inc_tax > 0
),
sr_join AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_net_loss,
        r.r_reason_id,
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_desc = 'Damaged'
),
ss_main AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_sold_date_sk,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_net_profit > 0
      AND ss.ss_sold_date_sk BETWEEN 2454899 AND 2455000
),
customer_revenue AS (
    SELECT
        ss.c_customer_sk,
        ss.c_first_name,
        ss.c_last_name,
        ss.c_birth_year,
        ss.hd_income_band_sk AS hdemo_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_web_sales,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_returns,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_returns,
        (SUM(ss.ss_net_paid) + COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) - COALESCE(SUM(sr.sr_net_loss), 0) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_revenue
    FROM ss_main ss
    LEFT JOIN ws_join ws ON ss.c_customer_sk = ws.c_customer_sk
    LEFT JOIN sr_join sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN cr_join cr ON ss.c_customer_sk = cr.c_customer_sk
    GROUP BY
        ss.c_customer_sk,
        ss.c_first_name,
        ss.c_last_name,
        ss.c_birth_year,
        ss.hd_income_band_sk
    HAVING (SUM(ss.ss_net_paid) + COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) - COALESCE(SUM(sr.sr_net_loss), 0) - COALESCE(SUM(cr.cr_net_loss), 0)) > 1000
)
SELECT
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.c_birth_year,
    rc.total_store_sales,
    rc.total_web_sales,
    rc.total_store_returns,
    rc.total_catalog_returns,
    rc.net_revenue,
    ROW_NUMBER() OVER (PARTITION BY rc.hdemo_sk ORDER BY rc.net_revenue DESC) AS revenue_rank
FROM customer_revenue rc
ORDER BY rc.net_revenue DESC
LIMIT 10
