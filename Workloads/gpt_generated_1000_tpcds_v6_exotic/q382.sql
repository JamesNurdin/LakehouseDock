WITH joined_all AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_fee,
        r.r_reason_desc,
        cc.cc_name,
        cp.cp_type,
        cc.cc_rec_start_date
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN call_center cc_alt
        ON cr.cr_call_center_sk = cc_alt.cc_call_center_sk
    JOIN catalog_page cp_alt
        ON cr.cr_catalog_page_sk = cp_alt.cp_catalog_page_sk
    JOIN reason r_alt
        ON cr.cr_reason_sk = r_alt.r_reason_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
)
SELECT
    r_reason_desc AS reason_desc,
    cc_name AS call_center_name,
    cp_type AS catalog_type,
    SUM(cr_return_amount + cr_return_tax + cr_fee) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM (
    SELECT * FROM joined_all WHERE cp_type = 'monthly'
    UNION ALL
    SELECT * FROM joined_all WHERE cp_type = 'quarterly'
) AS u
GROUP BY r_reason_desc, cc_name, cp_type
ORDER BY total_return_amount DESC
LIMIT 100
