WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_net_loss,
        cr_call_center_sk,
        cr_reason_sk
    FROM catalog_returns
    WHERE cr_reason_sk IN (
        SELECT r_reason_sk
        FROM reason
        WHERE regexp_like(r_reason_desc, '(?i)job')
    )
)
SELECT
    cc.cc_name,
    r.r_reason_desc,
    d.d_year,
    SUM(fr.cr_return_amount) AS total_return_amount,
    SUM(fr.cr_net_loss) AS total_net_loss,
    CONCAT(cc.cc_name, ' - ', r.r_reason_desc) AS combo_desc,
    SUBSTR(r.r_reason_desc, 1, 10) AS reason_prefix
FROM filtered_returns fr
JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d ON fr.cr_returned_date_sk = d.d_date_sk
WHERE cc.cc_city LIKE 'A%'
GROUP BY CUBE (cc.cc_name, r.r_reason_desc, d.d_year)
HAVING SUM(fr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
