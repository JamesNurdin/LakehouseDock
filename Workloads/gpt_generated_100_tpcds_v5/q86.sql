WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_addr_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss,
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_net_loss,
        cc.cc_state,
        sm.sm_carrier,
        ws.web_class,
        ca.ca_state,
        d.d_year,
        t.t_hour
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
)
SELECT
    base.d_year,
    base.cc_state,
    base.ca_state AS customer_state,
    base.sm_carrier,
    base.web_class,
    base.t_hour,
    COUNT(DISTINCT base.sr_returned_date_sk) AS store_return_days,
    SUM(base.sr_return_amt) AS total_store_return_amt,
    SUM(base.cr_return_amount) AS total_catalog_return_amt,
    SUM(base.wr_return_amt) AS total_web_return_amt,
    SUM(COALESCE(base.sr_return_amt, 0) + COALESCE(base.cr_return_amount, 0) + COALESCE(base.wr_return_amt, 0)) AS total_all_return_amt,
    AVG(COALESCE(base.sr_return_tax, 0) + COALESCE(base.cr_return_tax, 0) + COALESCE(base.wr_return_tax, 0)) AS avg_total_tax,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN COALESCE(base.sr_return_amt, 0) + COALESCE(base.cr_return_amount, 0) + COALESCE(base.wr_return_amt, 0) > 1000 THEN 1 ELSE 0 END) AS high_value_return_count
FROM base
WHERE
    base.cc_state = 'NY'
    AND base.sm_carrier = 'UPS'
    AND base.d_year = 2001
    AND base.t_hour BETWEEN 9 AND 17
    AND base.web_class = 'Unknown'
    AND base.ca_state = 'CA'
GROUP BY
    base.d_year,
    base.cc_state,
    base.ca_state,
    base.sm_carrier,
    base.web_class,
    base.t_hour
ORDER BY
    total_all_return_amt DESC
LIMIT 100
