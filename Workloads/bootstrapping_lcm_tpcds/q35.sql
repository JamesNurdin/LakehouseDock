SELECT
    s.s_market_desc,
    s.s_state,
    cp.cp_department,
    cp.cp_type,
    ws.web_mkt_desc,
    ws.web_state,
    dr_ret.d_year AS return_year,
    dr_ret.d_month_seq AS return_month,
    FLOOR(date_diff('day', dr_cp_start.d_date, dr_ret.d_date) / 30) AS months_since_catalog_start,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_return_ship_cost) AS total_ship_cost,
    SUM(wr.wr_return_amt - wr.wr_return_tax - wr.wr_return_ship_cost) AS net_return_excluding_tax_ship,
    AVG(wr.wr_return_amt_inc_tax) AS avg_return_inc_tax,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_order_cnt,
    SUM(CASE WHEN wr.wr_return_quantity > 5 THEN 1 ELSE 0 END) AS high_qty_return_cnt,
    SUM(CASE WHEN dr_ret.d_weekend = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS weekend_return_amount,
    SUM(CASE WHEN dr_ret.d_holiday = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS holiday_return_amount,
    MIN(dr_ret.d_date) AS earliest_return_date,
    MAX(dr_ret.d_date) AS latest_return_date,
    MAX(ws.web_close_date_sk) - MIN(ws.web_open_date_sk) AS site_open_close_sk_range,
    MAX(s.s_closed_date_sk) - MIN(s.s_closed_date_sk) AS store_closed_sk_range,
    SUM(wr.wr_fee) AS total_fee
FROM web_returns wr
JOIN date_dim dr_ret
    ON wr.wr_returned_date_sk = dr_ret.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = dr_ret.d_date_sk
JOIN date_dim dr_cp_start
    ON cp.cp_start_date_sk = dr_cp_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = dr_ret.d_date_sk
JOIN date_dim dr_site_close
    ON ws.web_close_date_sk = dr_site_close.d_date_sk
WHERE s.s_state = 'CA'
  AND ws.web_state = 'CA'
  AND dr_ret.d_year BETWEEN 2015 AND 2022
GROUP BY
    s.s_market_desc,
    s.s_state,
    cp.cp_department,
    cp.cp_type,
    ws.web_mkt_desc,
    ws.web_state,
    dr_ret.d_year,
    dr_ret.d_month_seq,
    FLOOR(date_diff('day', dr_cp_start.d_date, dr_ret.d_date) / 30)
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
