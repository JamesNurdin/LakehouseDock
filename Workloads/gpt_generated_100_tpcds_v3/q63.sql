SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    i.i_category,
    w.w_state AS warehouse_state,
    cc.cc_manager,
    ws.web_market_manager,
    COUNT(sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    MIN(sr.sr_return_amt) AS min_return_amount,
    MAX(sr.sr_return_amt) AS max_return_amount
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_close_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND cc.cc_manager = 'Travis Wilson'
  AND s.s_state = 'CA'
  AND i.i_category = 'Sports'
  AND w.w_state = 'MI'
  AND ws.web_market_manager = 'Gerald Craft'
  AND cd.cd_gender = 'M'
GROUP BY d.d_year, d.d_month_seq, s.s_store_name, i.i_category, w.w_state, cc.cc_manager, ws.web_market_manager
ORDER BY total_return_amount DESC
LIMIT 100
