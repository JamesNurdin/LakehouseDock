WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_call_center_sk,
        cr.cr_reason_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_tax >= 5
      AND cr.cr_return_quantity BETWEEN 1 AND 10
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND cr.cr_call_center_sk IS NOT NULL
      AND cr.cr_reason_sk IS NOT NULL
),
joined AS (
    SELECT
        fr.cr_returned_date_sk,
        fr.cr_return_amount,
        fr.cr_return_tax,
        fr.cr_net_loss,
        fr.cr_return_quantity,
        cc.cc_call_center_id,
        cc.cc_state,
        cc.cc_sq_ft,
        cc.cc_gmt_offset,
        r.r_reason_id,
        r.r_reason_desc
    FROM filtered_returns fr
    JOIN call_center cc
        ON fr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON fr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_sq_ft > 0
      AND cc.cc_state IN ('CA', 'TX', 'NY')
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND r.r_reason_desc LIKE '%color%'
),
aggregated AS (
    SELECT
        cc_call_center_id,
        r_reason_id,
        r_reason_desc,
        cc_state,
        SUM(cr_net_loss) AS total_net_loss
    FROM joined
    GROUP BY cc_call_center_id, r_reason_id, r_reason_desc, cc_state
)
SELECT DISTINCT
    cc_call_center_id,
    r_reason_id,
    r_reason_desc,
    cc_state,
    total_net_loss,
    RANK() OVER (PARTITION BY cc_call_center_id ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
WHERE total_net_loss > 0
  AND total_net_loss < 10000
  AND cc_state <> 'FL'
  AND r_reason_id <> 'AAAAAAAABBAAAAAA'
ORDER BY total_net_loss DESC, cc_call_center_id
LIMIT 100
