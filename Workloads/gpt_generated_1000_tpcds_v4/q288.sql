SELECT
    s.s_store_id,
    s.s_state,
    i.i_category,
    td_s.t_hour,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_count,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim td_s
  ON ss.ss_sold_time_sk = td_s.t_time_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim td_w
  ON ws.ws_sold_time_sk = td_w.t_time_sk
WHERE s.s_state = 'CA'
  AND i.i_current_price BETWEEN 10 AND 500
  AND td_s.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN call_center cc
          ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN reason r
          ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_item_sk = ss.ss_item_sk
          AND cr.cr_return_amount > 0
          AND cc.cc_name = 'West Coast Call Center'
    )
GROUP BY s.s_store_id, s.s_state, i.i_category, td_s.t_hour
ORDER BY total_store_sales DESC
LIMIT 100
