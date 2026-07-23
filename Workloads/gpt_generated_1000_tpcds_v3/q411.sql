WITH returns_by_cc AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        concat(cc.cc_city, ', ', cc.cc_state) AS location,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        MAX(wp.wp_url) FILTER (WHERE regexp_like(wp.wp_url, '^https?://[^/]+\\.com')) AS matched_url
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    WHERE regexp_like(cc.cc_name, '^Call Center [A-Z]')
      AND cc.cc_city LIKE '%York%'
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        d_ret.d_year,
        d_ret.d_month_seq
)
SELECT
    r.cc_name,
    r.location,
    r.d_year,
    r.d_month_seq,
    r.total_return_amount,
    r.total_net_loss,
    r.return_cnt,
    r.matched_url,
    (r.total_net_loss / NULLIF(r.total_return_amount, 0)) AS loss_to_amount_ratio,
    (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS overall_avg_net_loss
FROM returns_by_cc r
WHERE r.total_net_loss > (SELECT AVG(cr3.cr_net_loss) FROM catalog_returns cr3)
ORDER BY loss_to_amount_ratio DESC
LIMIT 100
