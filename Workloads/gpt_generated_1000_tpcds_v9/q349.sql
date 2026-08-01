SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_name,
    cp.cp_department,
    ws.web_name,
    hd.hd_buy_potential,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
    AVG(sr.sr_fee) AS avg_store_fee,
    MIN(cr.cr_return_amount) AS min_catalog_return,
    MAX(wr.wr_return_amt) AS max_web_return
FROM tpcds.date_dim d
JOIN tpcds.store_returns sr
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN tpcds.inventory i
  ON i.inv_date_sk = d.d_date_sk
JOIN tpcds.call_center cc
  ON cc.cc_closed_date_sk = d.d_date_sk
JOIN tpcds.catalog_page cp
  ON cp.cp_start_date_sk = d.d_date_sk
JOIN tpcds.web_page wp
  ON wp.wp_creation_date_sk = d.d_date_sk
JOIN tpcds.web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
JOIN tpcds.customer c
  ON c.c_first_shipto_date_sk = d.d_date_sk
JOIN tpcds.household_demographics hd
  ON hd.hd_demo_sk = c.c_current_hdemo_sk
WHERE d.d_year = 2000
  AND sr.sr_return_quantity > 5
  AND i.inv_quantity_on_hand > 1000
  AND cc.cc_state = 'CA'
GROUP BY
    d.d_year,
    d.d_month_seq,
    cc.cc_name,
    cp.cp_department,
    ws.web_name,
    hd.hd_buy_potential
ORDER BY total_store_return_amount DESC
LIMIT 100
