WITH base_agg AS (
   SELECT
     s.s_store_sk,
     s.s_store_name,
     cc.cc_call_center_sk,
     cc.cc_name AS call_center_name,
     cp.cp_department,
     i.i_category,
     hd.hd_buy_potential,
     SUM(cs.cs_net_profit) AS total_catalog_net_profit,
     SUM(ss.ss_net_profit) AS total_store_net_profit,
     SUM(sr.sr_net_loss) AS total_return_net_loss,
     SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
     COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
     COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
     (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(sr.sr_net_loss)) AS net_profit_after_returns
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE ca.ca_state = 'CA'
     AND s.s_state = 'CA'
     AND cc.cc_name = 'North Call Center'
     AND cp.cp_department = 'DEPARTMENT'
     AND hd.hd_buy_potential = '>10000'
     AND inv.inv_quantity_on_hand > 0
   GROUP BY
     s.s_store_sk,
     s.s_store_name,
     cc.cc_call_center_sk,
     cc.cc_name,
     cp.cp_department,
     i.i_category,
     hd.hd_buy_potential
)
SELECT
  s_store_sk,
  s_store_name,
  call_center_name,
  cp_department,
  i_category,
  hd_buy_potential,
  total_catalog_net_profit,
  total_store_net_profit,
  total_return_net_loss,
  total_inventory_qty,
  distinct_customers,
  distinct_web_pages,
  net_profit_after_returns
FROM base_agg
WHERE net_profit_after_returns > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
