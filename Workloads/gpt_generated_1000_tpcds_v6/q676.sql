WITH store_agg AS (
   SELECT
       ca.ca_county,
       ib.ib_lower_bound,
       SUM(ss.ss_net_profit) AS total_net_profit,
       COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
   FROM store_sales ss
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE ca.ca_gmt_offset = -5.00
     AND NOT EXISTS (
         SELECT 1 FROM web_sales ws
         WHERE ws.ws_bill_hdemo_sk = hd.hd_demo_sk
     )
   GROUP BY ca.ca_county, ib.ib_lower_bound
),

web_agg AS (
   SELECT
       ca.ca_county,
       ib.ib_lower_bound,
       SUM(ws.ws_net_profit) AS total_net_profit,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
   FROM web_sales ws
   JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
   WHERE ca.ca_state = 'CA'
     AND hd.hd_vehicle_count > 1
   GROUP BY ca.ca_county, ib.ib_lower_bound
)

SELECT DISTINCT
       combined.county,
       combined.lower_bound,
       combined.total_net_profit,
       combined.distinct_count,
       ROW_NUMBER() OVER (PARTITION BY combined.county ORDER BY combined.total_net_profit DESC) AS profit_rank
FROM (
   SELECT
       ca_county AS county,
       ib_lower_bound AS lower_bound,
       total_net_profit,
       distinct_tickets AS distinct_count
   FROM store_agg
   UNION ALL
   SELECT
       ca_county AS county,
       ib_lower_bound AS lower_bound,
       total_net_profit,
       distinct_orders AS distinct_count
   FROM web_agg
) AS combined
ORDER BY combined.total_net_profit DESC
LIMIT 100
