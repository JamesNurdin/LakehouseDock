WITH filtered_ship_modes AS (
    SELECT DISTINCT sm_ship_mode_sk, sm_ship_mode_id, sm_code, sm_contract
    FROM ship_mode
    WHERE sm_code IN ('AIR', 'SEA')
      AND sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
)
SELECT
    sm.sm_ship_mode_id,
    wsit.web_name,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_catalog_net,
    SUM(ws.ws_net_paid) AS total_web_net,
    AVG(cs.cs_quantity) AS avg_quantity,
    MIN(cs.cs_sales_price) AS min_sales_price,
    MAX(cs.cs_sales_price) AS max_sales_price
FROM catalog_sales cs
JOIN filtered_ship_modes sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE EXISTS (
        SELECT 1
        FROM call_center cc
        WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
          AND cc.cc_country = 'United States'
          AND cc.cc_zip = '28482'
          AND cc.cc_street_type = 'Avenue'
    )
  AND wsit.web_mkt_desc LIKE '%children%'
  AND wsit.web_company_id = 3
  AND cs.cs_sold_date_sk BETWEEN 2451000 AND 2452000
GROUP BY sm.sm_ship_mode_id, wsit.web_name
ORDER BY total_catalog_net DESC
LIMIT 100
