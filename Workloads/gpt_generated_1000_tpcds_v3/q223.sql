WITH detailed_returns AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_market_manager,
        d.d_date AS return_date,
        t.t_hour AS return_hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_tax) AS avg_return_tax
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE d.d_fy_quarter_seq = 6
      AND t.t_hour BETWEEN 9 AND 17
      AND cc.cc_market_manager IN ('Kevin Damico', 'Mark Camp')
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_market_manager,
        d.d_date,
        t.t_hour
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_market_manager,
    return_date,
    return_hour,
    total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_return_amount DESC) AS return_rank
FROM (
    SELECT
        cc_call_center_id,
        cc_name,
        cc_market_manager,
        return_date,
        return_hour,
        total_return_amount
    FROM detailed_returns
    WHERE total_return_amount > 500
    UNION ALL
    SELECT
        cc_call_center_id,
        cc_name,
        cc_market_manager,
        return_date,
        return_hour,
        total_return_amount
    FROM detailed_returns
    WHERE total_return_amount <= 500
      AND cc_market_manager = 'Kevin Damico'
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
