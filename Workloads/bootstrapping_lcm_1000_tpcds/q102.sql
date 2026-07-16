WITH aggregated AS (
    SELECT
        cc.cc_name,
        cc.cc_manager,
        s.s_store_name,
        s.s_city,
        d.d_year,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY
        cc.cc_name,
        cc.cc_manager,
        s.s_store_name,
        s.s_city,
        d.d_year,
        r.r_reason_desc
)
SELECT
    cc_name,
    cc_manager,
    s_store_name,
    s_city,
    d_year,
    reason_desc,
    total_return_amount,
    total_return_tax,
    total_net_loss,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS rank_within_year
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
