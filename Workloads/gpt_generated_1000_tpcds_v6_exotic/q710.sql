WITH returns_info AS (
    SELECT
        cr.cr_call_center_sk,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS cnt_customers,
        SUM(cr.cr_return_amount) AS total_return_amount,
        MIN(cr.cr_returned_date_sk) AS min_return_date_sk,
        MAX(cr.cr_returned_date_sk) AS max_return_date_sk
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
    GROUP BY cr.cr_call_center_sk
),
call_center_filtered AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_mkt_class,
        regexp_extract(cc.cc_name, '(\\w+) (Center)', 1) AS name_prefix,
        CASE
            WHEN cc.cc_name LIKE '%Call%' THEN 'HasCall'
            ELSE 'Other'
        END AS name_category,
        cc.cc_gmt_offset
    FROM call_center cc
    WHERE cc.cc_gmt_offset BETWEEN -5.00 AND 1.00
)
SELECT
    ccf.cc_call_center_sk,
    ccf.cc_name,
    ccf.name_prefix,
    ccf.name_category,
    COALESCE(ri.total_return_amount, 0) AS total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY ccf.cc_mkt_class ORDER BY COALESCE(ri.total_return_amount, 0) DESC) AS rn
FROM call_center_filtered ccf
LEFT JOIN returns_info ri ON ccf.cc_call_center_sk = ri.cr_call_center_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_call_center_sk = ccf.cc_call_center_sk
)
ORDER BY total_return_amount DESC, ccf.cc_name
LIMIT 100
