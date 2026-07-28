WITH sr AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
),
cr AS (
    SELECT
        cr.cr_order_number,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
)
SELECT
    dr1.d_date AS store_return_date,
    tr1.t_time AS store_return_time,
    cust_sr.c_customer_id AS store_customer_id,
    reason_sr.r_reason_desc AS store_return_reason,
    dr1.d_date AS catalog_return_date,               -- same date dimension reused for catalog return (joined via rule)
    tr2.t_time AS catalog_return_time,
    cust_ref.c_customer_id AS refunded_customer_id,
    cust_ret.c_customer_id AS returning_customer_id,
    cc.cc_name AS call_center_name,
    cp.cp_description AS catalog_page_desc,
    w.w_warehouse_name AS warehouse_name,
    reason_cr.r_reason_desc AS catalog_return_reason,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(cr.cr_return_amount) AS total_catalog_return_amt,
    ROW_NUMBER() OVER (PARTITION BY cust_sr.c_customer_id ORDER BY dr1.d_date DESC) AS rn_store_ret
FROM sr
JOIN date_dim dr1
    ON sr.sr_returned_date_sk = dr1.d_date_sk                               -- join rule 1
JOIN time_dim tr1
    ON sr.sr_return_time_sk = tr1.t_time_sk                                 -- join rule 2
JOIN customer cust_sr
    ON sr.sr_customer_sk = cust_sr.c_customer_sk                            -- join rule 3
JOIN reason reason_sr
    ON sr.sr_reason_sk = reason_sr.r_reason_sk                             -- join rule 4
JOIN cr
    ON cr.cr_returned_date_sk = dr1.d_date_sk                                 -- join rule 5 (reuse date_dim)
JOIN time_dim tr2
    ON cr.cr_returned_time_sk = tr2.t_time_sk                                 -- join rule 6
JOIN customer cust_ref
    ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk                  -- join rule 7
JOIN customer cust_ret
    ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk                  -- join rule 8
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk                         -- join rule 9
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk                        -- join rule 10
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk                                 -- join rule 11
JOIN reason reason_cr
    ON cr.cr_reason_sk = reason_cr.r_reason_sk                               -- join rule 12
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = sr.sr_ticket_number
    )
GROUP BY
    dr1.d_date,
    tr1.t_time,
    cust_sr.c_customer_id,
    reason_sr.r_reason_desc,
    tr2.t_time,
    cust_ref.c_customer_id,
    cust_ret.c_customer_id,
    cc.cc_name,
    cp.cp_description,
    w.w_warehouse_name,
    reason_cr.r_reason_desc
ORDER BY total_store_return_amt DESC
LIMIT 100
