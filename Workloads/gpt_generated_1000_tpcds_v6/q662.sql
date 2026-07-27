WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_reversed_charge,
        cr.cr_net_loss,
        cr.cr_refunded_addr_sk,
        cr.cr_refunded_cdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_reversed_charge > 100.00
)
SELECT
    cc.cc_name,
    d_ret.d_year AS return_year,
    ca_ref.ca_state AS refunded_state,
    cd_ref.cd_gender AS refunded_gender,
    COUNT(*) AS num_returns,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_reversed_charge) AS avg_reversed_charge,
    MIN(fr.cr_net_loss) AS min_net_loss,
    MAX(fr.cr_net_loss) AS max_net_loss,
    (SELECT AVG(cr2.cr_reversed_charge) FROM catalog_returns cr2) AS overall_avg_reversed_charge
FROM filtered_returns fr
JOIN call_center cc
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON fr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer_address ca_ref
    ON fr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_ref
    ON fr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
WHERE
    cc.cc_street_type = 'Avenue'
    AND cc.cc_mkt_desc LIKE '%Common%'
    AND cc.cc_rec_end_date >= DATE '2000-01-01'
    AND ca_ref.ca_gmt_offset = -6.00
    AND d_ret.d_year = 2000
GROUP BY
    cc.cc_name,
    d_ret.d_year,
    ca_ref.ca_state,
    cd_ref.cd_gender
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
