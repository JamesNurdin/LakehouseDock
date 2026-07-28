WITH ss_agg AS (
   SELECT
      ss_item_sk,
      ss_sold_date_sk,
      ss_sold_time_sk,
      ss_ticket_number,
      ss_cdemo_sk,
      ss_hdemo_sk,
      ss_addr_sk,
      SUM(ss_net_paid) AS total_net_paid,
      SUM(ss_net_profit) AS total_net_profit,
      COUNT(*) AS sales_cnt
   FROM store_sales
   GROUP BY ss_item_sk, ss_sold_date_sk, ss_sold_time_sk,
            ss_ticket_number, ss_cdemo_sk, ss_hdemo_sk, ss_addr_sk
)
SELECT
   d_sold.d_year,
   i.i_category,
   i.i_brand,
   MAX(cc.cc_name) AS call_center_name,
   MAX(cp.cp_type) AS catalog_page_type,
   MAX(wp.wp_url) AS web_page_url,
   MAX(cd.cd_gender) AS gender,
   MAX(hd.hd_buy_potential) AS buy_potential,
   SUM(ssa.total_net_paid) AS sum_net_paid,
   SUM(ssa.total_net_profit) AS sum_net_profit,
   COUNT(*) AS txn_count
FROM ss_agg ssa
JOIN item i
  ON i.i_item_sk = ssa.ss_item_sk
JOIN date_dim d_sold
  ON d_sold.d_date_sk = ssa.ss_sold_date_sk
JOIN time_dim t_sold
  ON t_sold.t_time_sk = ssa.ss_sold_time_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = ssa.ss_cdemo_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = ssa.ss_hdemo_sk
JOIN customer_address ca
  ON ca.ca_address_sk = ssa.ss_addr_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = ssa.ss_item_sk
 AND sr.sr_ticket_number = ssa.ss_ticket_number
LEFT JOIN date_dim d_ret
  ON d_ret.d_date_sk = sr.sr_returned_date_sk
LEFT JOIN time_dim t_ret
  ON t_ret.t_time_sk = sr.sr_return_time_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = ssa.ss_item_sk
LEFT JOIN catalog_page cp
  ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN call_center cc
  ON cc.cc_call_center_sk = cr.cr_call_center_sk
LEFT JOIN web_sales ws
  ON ws.ws_item_sk = ssa.ss_item_sk
LEFT JOIN date_dim d_ws_sold
  ON d_ws_sold.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN web_page wp
  ON wp.wp_web_page_sk = ws.ws_web_page_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = ssa.ss_item_sk
 AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d_sold.d_date_sk
GROUP BY GROUPING SETS (
   (d_sold.d_year, i.i_category, i.i_brand),
   (d_sold.d_year, i.i_category),
   (d_sold.d_year),
   ()
)
ORDER BY d_sold.d_year DESC, i.i_category, i.i_brand
LIMIT 100
