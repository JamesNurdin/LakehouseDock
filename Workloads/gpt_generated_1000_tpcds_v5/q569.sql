WITH agg_returns AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_class,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_count,
        CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_class IN ('small', 'medium')
      AND cc.cc_tax_percentage >= 0.05
      AND cr.cr_store_credit > 10
      AND cr.cr_refunded_cash IS NOT NULL
      AND EXISTS (
          SELECT 1
          FROM tpcds.web_returns wr
          WHERE wr.wr_reason_sk = r.r_reason_sk
            AND wr.wr_refunded_cash > 50
      )
    GROUP BY cc.cc_call_center_id, cc.cc_class, r.r_reason_desc
)
SELECT
    loss_category,
    COUNT(*) AS centers_in_category,
    AVG(total_net_loss) AS avg_net_loss,
    SUM(total_refunded_cash) AS total_refunded_cash_all
FROM agg_returns
WHERE total_net_loss > 0
GROUP BY loss_category
ORDER BY avg_net_loss DESC
LIMIT 100
