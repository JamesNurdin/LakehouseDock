WITH aggregated AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        sm.sm_ship_mode_sk,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(cr.cr_refunded_cash) AS avg_refunded_cash,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_zip LIKE '339%'
      AND sm.sm_code IN ('AIR', 'SEA')
      AND cr.cr_return_amount > 100
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        sm.sm_ship_mode_sk,
        sm.sm_type
    HAVING
        SUM(cr.cr_return_amount) > 500
        AND COUNT(*) >= 5
        AND AVG(cr.cr_refunded_cash) > 50
)
SELECT
    agg.cc_name,
    agg.sm_type,
    agg.total_return_amount,
    agg.total_return_quantity,
    agg.avg_refunded_cash,
    agg.return_cnt,
    agg.amount_category,
    CASE WHEN agg.total_return_quantity > 10 THEN 'Bulk' ELSE 'Small' END AS qty_category,
    SUM(agg.total_return_amount) OVER (
        PARTITION BY agg.sm_type
        ORDER BY agg.total_return_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_ship_type,
    RANK() OVER (ORDER BY agg.total_return_amount DESC) AS amount_rank
FROM aggregated agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
