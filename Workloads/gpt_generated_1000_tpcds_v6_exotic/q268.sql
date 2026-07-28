WITH cs_agg AS (
       SELECT
           cs.cs_bill_addr_sk AS addr_sk,
           COUNT(*) AS cs_orders,
           SUM(cs.cs_net_profit) AS cs_total_profit,
           SUM(cs.cs_quantity) AS cs_total_quantity
       FROM catalog_sales cs
       JOIN catalog_page cp
         ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
       WHERE cs.cs_quantity > 5
         AND cp.cp_department = 'Electronics'
       GROUP BY cs.cs_bill_addr_sk
   ),
   ws_agg AS (
       SELECT
           ws.ws_bill_addr_sk AS addr_sk,
           COUNT(*) AS ws_orders,
           SUM(ws.ws_net_profit) AS ws_total_profit,
           SUM(ws.ws_quantity) AS ws_total_quantity
       FROM web_sales ws
       WHERE ws.ws_quantity >= 3
         AND ws.ws_ext_tax > 10
       GROUP BY ws.ws_bill_addr_sk
   ),
   sr_agg AS (
       SELECT
           sr.sr_addr_sk AS addr_sk,
           s.s_store_name,
           SUM(sr.sr_return_amt) AS sr_total_return_amt,
           SUM(sr.sr_net_loss) AS sr_total_net_loss
       FROM store_returns sr
       JOIN store s
         ON sr.sr_store_sk = s.s_store_sk
       WHERE sr.sr_return_ship_cost > 0
       GROUP BY sr.sr_addr_sk, s.s_store_name
   ),
   wr_agg AS (
       SELECT
           wr.wr_refunded_addr_sk AS addr_sk,
           SUM(wr.wr_return_amt) AS wr_total_return_amt,
           SUM(wr.wr_net_loss) AS wr_total_net_loss
       FROM web_returns wr
       WHERE wr.wr_return_amt > 20
       GROUP BY wr.wr_refunded_addr_sk
   )
SELECT DISTINCT
       ca.ca_address_id,
       ca.ca_state,
       cs_agg.cs_orders,
       cs_agg.cs_total_profit,
       ws_agg.ws_orders,
       ws_agg.ws_total_profit,
       sr_agg.s_store_name,
       sr_agg.sr_total_return_amt,
       wr_agg.wr_total_return_amt,
       ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY (COALESCE(cs_agg.cs_total_profit,0) + COALESCE(ws_agg.ws_total_profit,0)) DESC) AS rn_state_profit
FROM customer_address ca
LEFT JOIN cs_agg
       ON ca.ca_address_sk = cs_agg.addr_sk
LEFT JOIN ws_agg
       ON ca.ca_address_sk = ws_agg.addr_sk
LEFT JOIN sr_agg
       ON ca.ca_address_sk = sr_agg.addr_sk
LEFT JOIN wr_agg
       ON ca.ca_address_sk = wr_agg.addr_sk
WHERE ca.ca_gmt_offset BETWEEN -5 AND 5
  AND ca.ca_country = 'United States'
  AND (cs_agg.cs_orders IS NOT NULL OR ws_agg.ws_orders IS NOT NULL)
ORDER BY rn_state_profit
LIMIT 100
