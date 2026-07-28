WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        s.s_store_name,
        c.c_customer_id,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_dep_employed_count,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r_ret.r_reason_desc AS return_reason,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        ws.ws_quantity AS web_quantity,
        ws.ws_net_paid AS web_net_paid,
        r_cr.r_reason_desc AS catalog_return_reason,
        sm_cr.sm_carrier AS catalog_ship_carrier,
        sm_ws.sm_carrier AS web_ship_carrier
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_ret ON sr.sr_reason_sk = r_ret.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    WHERE
        sr.sr_cdemo_sk IN (1568019, 463971, 1097964)
        AND cd.cd_dep_employed_count > 2
        AND c.c_email_address LIKE '%@%.edu'
        AND ws.ws_quantity > 1
        AND cr.cr_return_amount > 100
)
SELECT
    store_name,
    customer_id,
    email_address,
    gender,
    education_status,
    dep_employed_count,
    total_sales,
    total_returns,
    net_loss,
    return_reason,
    catalog_return_reason,
    ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY net_loss DESC) AS loss_rank,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        s_store_name AS store_name,
        c_customer_id AS customer_id,
        c_email_address AS email_address,
        cd_gender AS gender,
        cd_education_status AS education_status,
        cd_dep_employed_count AS dep_employed_count,
        SUM(ss_net_paid) AS total_sales,
        SUM(COALESCE(sr_return_amt, 0)) AS total_returns,
        SUM(COALESCE(sr_net_loss, 0) + COALESCE(cr_net_loss, 0)) AS net_loss,
        MAX(return_reason) AS return_reason,
        MAX(catalog_return_reason) AS catalog_return_reason
    FROM base
    GROUP BY
        s_store_name,
        c_customer_id,
        c_email_address,
        cd_gender,
        cd_education_status,
        cd_dep_employed_count
) t
ORDER BY net_loss DESC, sales_rank
LIMIT 100
