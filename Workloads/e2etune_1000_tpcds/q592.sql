WITH monthly_returns AS (
    SELECT
        cr.cr_call_center_sk,
        d.d_year,
        d.d_month_seq,
        sm.sm_ship_mode_id AS ship_mode_id,
        COUNT(DISTINCT cr.cr_order_number) AS return_cnt,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(cr.cr_fee) AS total_fee,
        AVG(cr.cr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY cr.cr_call_center_sk, d.d_year, d.d_month_seq, sm.sm_ship_mode_id
)
SELECT
    cc.cc_call_center_id,
    cc.cc_market_manager,
    mr.d_year,
    mr.d_month_seq,
    mr.ship_mode_id,
    mr.return_cnt,
    mr.net_loss,
    mr.total_fee,
    mr.avg_return_amt_inc_tax,
    ROUND(mr.net_loss / NULLIF(mr.return_cnt, 0), 2) AS avg_loss_per_return
FROM monthly_returns mr
JOIN call_center cc ON mr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_market_manager = 'Julius Tran'
  AND mr.net_loss > 0
ORDER BY mr.net_loss DESC
LIMIT 200
