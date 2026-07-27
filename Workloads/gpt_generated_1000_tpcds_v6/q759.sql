WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_call_center_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
    )
)
SELECT
    cc.cc_division_name,
    cc.cc_city,
    CONCAT(cc.cc_name, ' - ', cc.cc_state) AS call_center_full_name,
    COUNT(DISTINCT crf.cr_order_number) AS distinct_orders,
    SUM(crf.cr_net_loss) AS total_net_loss,
    AVG(crf.cr_return_amount) AS avg_return_amount
FROM filtered_returns crf
JOIN call_center cc
    ON crf.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_demographics cd_refunded
    ON crf.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON crf.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
WHERE
    regexp_like(cd_refunded.cd_education_status, 'Degree')
    AND regexp_like(cd_returning.cd_education_status, 'Degree')
    AND cd_refunded.cd_dep_college_count > 0
    AND cd_returning.cd_dep_college_count > 0
    AND cc.cc_street_number LIKE '9%'
    AND regexp_extract(cc.cc_name, '^([A-Za-z]+)', 1) IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM call_center cc2
        WHERE cc2.cc_division = cc.cc_division
          AND cc2.cc_gmt_offset > 0
          AND cc2.cc_country = 'United States'
    )
GROUP BY
    cc.cc_division_name,
    cc.cc_city,
    cc.cc_name,
    cc.cc_state
ORDER BY total_net_loss DESC
LIMIT 100
