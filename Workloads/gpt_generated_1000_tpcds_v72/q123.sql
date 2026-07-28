WITH catalog_agg AS (
  SELECT
    ca.ca_state,
    ca.ca_county,
    w.w_warehouse_name,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    AVG(cs.cs_net_profit) AS avg_catalog_profit
  FROM catalog_sales cs
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE regexp_like(ca.ca_county, 'County$')
    AND ca.ca_city LIKE '%Ville%'
  GROUP BY ca.ca_state, ca.ca_county, w.w_warehouse_name
),
web_agg AS (
  SELECT
    ca.ca_state,
    ca.ca_county,
    w.w_warehouse_name,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    AVG(ws.ws_net_profit) AS avg_web_profit
  FROM web_sales ws
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE regexp_like(ca.ca_county, '^W.*County')
    AND ca.ca_city LIKE 'San_%'
  GROUP BY ca.ca_state, ca.ca_county, w.w_warehouse_name
)
SELECT
  cat.ca_state,
  cat.w_warehouse_name,
  cat.ca_county,
  cat.total_catalog_sales,
  web.total_web_sales,
  (cat.total_catalog_sales + web.total_web_sales) AS combined_sales,
  cat.avg_catalog_profit,
  web.avg_web_profit,
  ROUND((cat.avg_catalog_profit + web.avg_web_profit) / 2, 2) AS combined_avg_profit,
  ROW_NUMBER() OVER (ORDER BY (cat.total_catalog_sales + web.total_web_sales) DESC) AS sales_rank,
  CONCAT(cat.w_warehouse_name, '-', cat.ca_state) AS location_key,
  regexp_extract(cat.ca_county, '([A-Za-z]+) County', 1) AS county_name,
  (SELECT AVG(cs_net_profit) FROM catalog_sales) AS overall_catalog_avg_profit,
  CASE WHEN EXISTS (
        SELECT 1 FROM call_center cc
        WHERE cc.cc_state = cat.ca_state
          AND cc.cc_name LIKE '%Center%'
      ) THEN 'Has Call Center' ELSE 'No Call Center' END AS call_center_flag
FROM catalog_agg cat
JOIN web_agg web
  ON cat.ca_state = web.ca_state
 AND cat.w_warehouse_name = web.w_warehouse_name
WHERE cat.total_catalog_sales > 5000
ORDER BY combined_sales DESC
LIMIT 100
