WITH returns_agg AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_returned_date_sk,
        s.s_store_sk,
        ws.web_site_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    GROUP BY
        cr.cr_call_center_sk,
        cr.cr_returned_date_sk,
        s.s_store_sk,
        ws.web_site_sk,
        d_ret.d_year,
        d_ret.d_month_seq
)
SELECT
    cc.cc_call_center_sk,
    cc.cc_name AS call_center_name,
    cc.cc_division,
    cc.cc_tax_percentage,
    s.s_store_sk,
    s.s_store_name,
    s.s_tax_percentage,
    ws.web_site_sk,
    ws.web_name,
    ws.web_tax_percentage,
    ra.d_year,
    ra.d_month_seq,
    ra.total_net_loss,
    ra.total_return_amount,
    ra.total_fee,
    ra.avg_return_tax,
    ra.return_cnt,
    d_cc_open.d_year AS cc_open_year,
    d_cc_closed.d_year AS cc_closed_year,
    d_ws_open.d_year AS ws_open_year,
    d_ws_close.d_year AS ws_close_year,
    ra.total_net_loss *
        (1 + cc.cc_tax_percentage / 100) *
        (1 + s.s_tax_percentage / 100) *
        (1 + ws.web_tax_percentage / 100) AS adjusted_net_loss,
    ROW_NUMBER() OVER (PARTITION BY ra.d_year ORDER BY ra.total_net_loss DESC) AS loss_rank_year
FROM returns_agg ra
JOIN call_center cc
    ON ra.cr_call_center_sk = cc.cc_call_center_sk
JOIN store s
    ON ra.s_store_sk = s.s_store_sk
JOIN web_site ws
    ON ra.web_site_sk = ws.web_site_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_ws_open
    ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
ORDER BY ra.total_net_loss DESC
LIMIT 100
