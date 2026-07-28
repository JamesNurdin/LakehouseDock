WITH store_data AS (
   SELECT s.s_store_name AS channel,
          'Store' AS channel_type,
          ss.ss_net_profit AS profit,
          ss.ss_quantity AS qty,
          ss.ss_ticket_number AS ticket
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   WHERE s.s_state = 'CA'
),
catalog_data AS (
   SELECT cc.cc_name AS channel,
          'Catalog' AS channel_type,
          cs.cs_net_profit AS profit,
          cs.cs_quantity AS qty,
          cs.cs_order_number AS ticket
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE cc.cc_state = 'CA'
)
SELECT
   channel_type,
   channel,
   SUM(profit) AS total_profit,
   SUM(qty) AS total_quantity,
   COUNT(DISTINCT ticket) AS order_count
FROM (
   SELECT * FROM store_data
   UNION ALL
   SELECT * FROM catalog_data
) AS combined
GROUP BY GROUPING SETS (
   (channel_type, channel),
   (channel_type),
   ()
)
ORDER BY
   channel_type,
   channel
LIMIT 100
