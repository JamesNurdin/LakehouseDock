WITH store_agg AS (
   SELECT
       r.r_reason_desc AS category,
       ca.ca_county AS county,
       SUM(sr.sr_net_loss) AS amount,
       COUNT(*) AS cnt,
       AVG(sr.sr_fee) AS avg_metric
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE r.r_reason_desc = 'Package was damaged'
     AND ca.ca_county = 'Maricopa County'
     AND sr.sr_fee > 10
   GROUP BY r.r_reason_desc, ca.ca_county
),
sales_agg AS (
   SELECT
       w.w_warehouse_name AS category,
       ca.ca_county AS county,
       SUM(ws.ws_net_profit) AS amount,
       COUNT(*) AS cnt,
       AVG(ws.ws_quantity) AS avg_metric
   FROM web_sales ws
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE w.w_state = 'CA'
     AND ca.ca_county = 'Maricopa County'
     AND ws.ws_quantity >= 5
   GROUP BY w.w_warehouse_name, ca.ca_county
)
SELECT source_type, category, county, amount, cnt, avg_metric
FROM (
   SELECT
       'Return' AS source_type,
       category,
       county,
       amount,
       cnt,
       avg_metric
   FROM store_agg
   UNION ALL
   SELECT
       'Sale' AS source_type,
       category,
       county,
       amount,
       cnt,
       avg_metric
   FROM sales_agg
) combined
ORDER BY source_type, amount DESC
