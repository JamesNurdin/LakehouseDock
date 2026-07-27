WITH d AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1 AND 12
)
SELECT
    cc.cc_call_center_id,
    cp.cp_catalog_page_id,
    s.s_store_id,
    w.w_warehouse_id,
    td.t_time,
    wr.wr_return_amt,
    sr.sr_return_amt,
    inv.inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY wr.wr_return_amt DESC) AS rn_return_amt_rank,
    CASE WHEN wr.wr_return_amt > 1000 THEN 'High' ELSE 'Normal' END AS return_category
FROM d
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_store_sk = s.s_store_sk
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cc.cc_state = 'CA'
  AND w.w_state = 'CA'
  AND s.s_state = 'CA'
  AND wr.wr_return_amt > 0
ORDER BY wr.wr_return_amt DESC
LIMIT 100
