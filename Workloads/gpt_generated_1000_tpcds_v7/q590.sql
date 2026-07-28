WITH base AS (
    SELECT
        cc.cc_market_manager AS market_manager,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_manufact_id IN (630, 169)
      AND i.i_class_id = 14
      AND i.i_rec_end_date > DATE '2000-01-01'
      AND r.r_reason_id = 'AAAAAAAAFAAAAAAA'
      AND cc.cc_market_manager = 'Mark Camp'
      AND cr.cr_return_amount > 0
    GROUP BY cc.cc_market_manager, r.r_reason_desc
)
SELECT
    market_manager,
    AVG(total_return_amount) AS avg_total_return_amount,
    SUM(return_cnt) AS total_returns
FROM base
GROUP BY market_manager
HAVING AVG(total_return_amount) > 5000
ORDER BY avg_total_return_amount DESC
