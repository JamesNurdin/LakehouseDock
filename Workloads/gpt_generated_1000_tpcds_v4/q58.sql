WITH agg AS (
    SELECT
        cr.cr_call_center_sk,
        td.t_hour,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(cr.cr_net_loss) AS sum_net_loss,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE
        cr.cr_return_amount > 100
        AND cr.cr_return_amount < 2000
        AND cr.cr_return_quantity BETWEEN 1 AND 10
        AND cr.cr_return_tax >= 0
        AND cr.cr_fee >= 0
        AND EXISTS (
            SELECT 1
            FROM call_center cc
            WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
              AND cc.cc_mkt_class LIKE '%National%'
              AND cc.cc_open_date_sk > 2450800
        )
        AND td.t_am_pm = 'PM'
        AND td.t_hour IN (6, 7, 8, 17)
    GROUP BY
        cr.cr_call_center_sk,
        td.t_hour
)
SELECT
    cc.cc_call_center_id,
    cc.cc_mkt_class,
    agg.t_hour,
    agg.sum_return_amount,
    agg.sum_net_loss,
    agg.cnt_returns,
    agg.sum_return_amount / NULLIF(agg.cnt_returns, 0) AS avg_return_amount,
    agg.sum_net_loss / NULLIF(agg.cnt_returns, 0) AS avg_net_loss
FROM agg
JOIN call_center cc
    ON agg.cr_call_center_sk = cc.cc_call_center_sk
WHERE
    agg.sum_return_amount > 500
    AND agg.sum_net_loss > 100
    AND cc.cc_state = 'CA'
    AND cc.cc_country = 'United States'
    AND cc.cc_employees BETWEEN 50 AND 500
    AND cc.cc_tax_percentage < 10
ORDER BY agg.sum_net_loss DESC
LIMIT 100
