/*
Goal: Aggregate web return amounts and net loss by return year and item category, linking returns to customers, households, web pages, call centers, promotions and multiple date roles, demonstrating deep joins with reused dimension tables.
*/
SELECT
  dr.d_year AS return_year,
  i.i_category,
  SUM(wr.wr_return_amt) AS total_return_amount,
  SUM(wr.wr_net_loss) AS total_net_loss,
  COUNT(*) AS num_returns,
  MIN(cc.cc_state) AS sample_state
FROM tpcds.web_returns wr
JOIN tpcds.date_dim dr               ON wr.wr_returned_date_sk = dr.d_date_sk               -- return date
JOIN tpcds.time_dim t                ON wr.wr_returned_time_sk = t.t_time_sk               -- return time
JOIN tpcds.item i                    ON wr.wr_item_sk = i.i_item_sk                       -- returned item
JOIN tpcds.customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk   -- refunded customer demo
JOIN tpcds.customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk   -- returning customer demo
JOIN tpcds.household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk   -- refunded household demo
JOIN tpcds.household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk   -- returning household demo
JOIN tpcds.web_page wp               ON wr.wr_web_page_sk = wp.wp_web_page_sk               -- web page of the return
JOIN tpcds.date_dim d_creation       ON wp.wp_creation_date_sk = d_creation.d_date_sk       -- page creation date
JOIN tpcds.date_dim d_access         ON wp.wp_access_date_sk = d_access.d_date_sk           -- page access date
JOIN tpcds.call_center cc            ON cc.cc_open_date_sk = dr.d_date_sk                    -- call center open date matches return date
JOIN tpcds.date_dim d_close          ON cc.cc_closed_date_sk = d_close.d_date_sk             -- call center closed date
JOIN tpcds.promotion p               ON p.p_item_sk = i.i_item_sk                           -- promotion tied to the item
JOIN tpcds.date_dim d_p_start        ON p.p_start_date_sk = d_p_start.d_date_sk              -- promotion start date
JOIN tpcds.date_dim d_p_end          ON p.p_end_date_sk = d_p_end.d_date_sk                  -- promotion end date
WHERE dr.d_year = 2001
  AND p.p_discount_active = 'Y'
GROUP BY GROUPING SETS ((dr.d_year, i.i_category), (dr.d_year), ())
ORDER BY total_return_amount DESC
LIMIT 100
