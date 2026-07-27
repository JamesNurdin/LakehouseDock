WITH filtered_ship AS (
    SELECT sm_ship_mode_sk,
           sm_ship_mode_id,
           sm_contract
    FROM ship_mode
    WHERE sm_ship_mode_id IN ('AAAAAAAADAAAAAAA', 'AAAAAAAABAAAAAA')
      AND sm_contract LIKE 'yVf%'
),
filtered_site AS (
    SELECT web_site_sk,
           web_company_name,
           web_county,
           web_gmt_offset
    FROM web_site
    WHERE web_company_name IN ('ese', 'anti')
      AND web_county = 'Williamson County'
      AND web_gmt_offset = -6.00
)
SELECT
    sm.sm_ship_mode_id,
    site.web_site_sk,
    site.web_company_name,
    COUNT(ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_tax) AS avg_tax,
    MIN(ws.ws_ext_wholesale_cost) AS min_wholesale,
    MAX(ws.ws_ext_wholesale_cost) AS max_wholesale
FROM web_sales ws
JOIN filtered_ship sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN filtered_site site ON ws.ws_web_site_sk = site.web_site_sk
WHERE ws.ws_ext_tax > 20.00
  AND ws.ws_ext_wholesale_cost BETWEEN 500.00 AND 2000.00
  AND ws.ws_quantity >= 2
  AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
  AND ws.ws_ext_discount_amt < 50.00
  AND ws.ws_coupon_amt = 0.00
GROUP BY sm.sm_ship_mode_id,
         site.web_site_sk,
         site.web_company_name
HAVING SUM(ws.ws_net_profit) > (
    SELECT AVG(ws_net_profit) FROM web_sales
)
ORDER BY total_profit DESC
LIMIT 100
