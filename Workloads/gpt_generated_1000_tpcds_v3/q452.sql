SELECT
    d.d_date,
    d.d_quarter_name,
    cc.cc_name,
    cc.cc_state,
    sm.sm_carrier,
    sm.sm_code,
    r.r_reason_desc,
    ca.ca_city,
    hd.hd_income_band_sk,
    s.s_store_name,
    s.s_market_manager,
    cr.cr_return_amount,
    wr.wr_return_amt,
    (cr.cr_return_amount + wr.wr_return_amt) AS total_return_amount,
    (SELECT avg(cr2.cr_return_amount)
     FROM tpcds.catalog_returns cr2
     WHERE cr2.cr_reason_sk = cr.cr_reason_sk) AS avg_return_amount_for_reason,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cr.cr_return_amount DESC) AS store_return_rank,
    ws.web_name
FROM tpcds.catalog_returns cr
JOIN tpcds.date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN tpcds.household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_quarter_name = '1904Q2'
    AND cc.cc_state = 'TX'
    AND sm.sm_carrier = 'UPS'
    AND sm.sm_code = 'AIR'
    AND s.s_market_manager = 'Michael Wilson'
    AND cr.cr_return_amount > 1000
    AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_refunded_addr_sk = ca.ca_address_sk
          AND wr2.wr_return_amt > 500
    )
ORDER BY total_return_amount DESC
LIMIT 100
