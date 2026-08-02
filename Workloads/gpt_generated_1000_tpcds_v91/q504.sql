WITH returns_by_cc_and_reason AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_reason_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_store_credit) AS avg_store_credit
    FROM catalog_returns AS cr
    WHERE cr.cr_store_credit > 20
      AND cr.cr_net_loss > 0
      AND cr.cr_return_quantity > 1
      AND cr.cr_return_amount > 10
    GROUP BY cr.cr_call_center_sk, cr.cr_reason_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_division_name,
    cc.cc_zip,
    r.r_reason_desc,
    r.r_reason_id,
    rb.total_net_loss,
    rb.return_cnt,
    CASE
        WHEN rb.avg_store_credit >= 1000 THEN 'High'
        WHEN rb.avg_store_credit >= 100 THEN 'Medium'
        ELSE 'Low'
    END AS store_credit_category,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_division_name ORDER BY rb.total_net_loss DESC) AS rn_division,
    RANK() OVER (ORDER BY rb.total_net_loss DESC) AS overall_rank,
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name
FROM returns_by_cc_and_reason AS rb
JOIN call_center cc
    ON rb.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
    ON rb.cr_reason_sk = r.r_reason_sk
CROSS JOIN LATERAL (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
    FROM catalog_returns cr2
    JOIN customer c
        ON cr2.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
      AND cr2.cr_reason_sk = r.r_reason_sk
    ORDER BY cr2.cr_net_loss DESC
    LIMIT 1
) AS cust
WHERE cc.cc_zip IN ('33951', '74536', '85804')
  AND cc.cc_division_name = 'able'
  AND r.r_reason_desc LIKE '%color%'
  AND cc.cc_country = 'United States'
ORDER BY overall_rank
LIMIT 100
