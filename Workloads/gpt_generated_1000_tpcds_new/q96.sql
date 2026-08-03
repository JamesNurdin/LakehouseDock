WITH base1 AS (
   SELECT
       i.i_item_id,
       i.i_category,
       cc.cc_name,
       cd.cd_gender,
       SUM(cs.cs_net_paid) AS total_net_paid,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
       AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand,
       MAX(ws.ws_net_profit) AS max_net_profit
   FROM tpcds.store_sales ss
   JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
   JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
   JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
   JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
   JOIN tpcds.catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
   WHERE i.i_manufact_id = 214
     AND inv.inv_quantity_on_hand > 500
     AND cc.cc_state = 'CA'
     AND cr.cr_return_amount > 500
     AND ws.ws_net_profit > 0
   GROUP BY i.i_item_id, i.i_category, cc.cc_name, cd.cd_gender
),
base2 AS (
   SELECT
       i.i_item_id,
       i.i_category,
       cc.cc_name,
       cd.cd_gender,
       SUM(cs.cs_net_paid) AS total_net_paid,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
       AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand,
       MAX(ws.ws_net_profit) AS max_net_profit
   FROM tpcds.store_sales ss
   JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
   JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
   JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
   JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
   JOIN tpcds.catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
   WHERE i.i_manufact_id = 630
     AND inv.inv_quantity_on_hand < 200
     AND cc.cc_state = 'TX'
     AND cr.cr_return_amount > 1000
     AND ws.ws_net_profit > 10
   GROUP BY i.i_item_id, i.i_category, cc.cc_name, cd.cd_gender
),
union_all AS (
   SELECT * FROM base1
   UNION DISTINCT
   SELECT * FROM base2
)
SELECT
    u.i_item_id,
    u.i_category,
    u.cc_name,
    u.cd_gender,
    u.total_net_paid,
    u.total_return_amount,
    u.order_cnt,
    u.avg_qty_on_hand,
    u.max_net_profit,
    ROW_NUMBER() OVER (PARTITION BY u.i_item_id ORDER BY u.total_net_paid DESC) AS sales_rank
FROM union_all u
ORDER BY u.total_net_paid DESC
LIMIT 100
