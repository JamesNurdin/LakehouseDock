WITH sub1 AS (
   SELECT
     sm.sm_ship_mode_id,
     ca.ca_state,
     wsite.web_city,
     CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'NotProfitable' END AS profit_category,
     lt.lateral_total,
     (
        SELECT max(ws2.ws_net_paid_inc_tax)
        FROM web_sales ws2
        WHERE ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk
     ) AS max_net_paid
   FROM web_sales ws
   RIGHT OUTER JOIN ship_mode sm
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN customer_address ca
     ON ws.ws_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN web_site wsite
     ON ws.ws_web_site_sk = wsite.web_site_sk
   CROSS JOIN LATERAL (
     SELECT ws.ws_quantity * ws.ws_sales_price AS lateral_total
   ) lt
   WHERE EXISTS (
           SELECT 1
           FROM web_site ws2
           WHERE ws2.web_site_sk = ws.ws_web_site_sk
             AND ws2.web_city = 'Lakeview'
         )
     AND wsite.web_gmt_offset = -5.00
     AND ca.ca_gmt_offset = -5.00
),
sub2 AS (
   SELECT
     sm.sm_ship_mode_id,
     ca.ca_state,
     wsite.web_city,
     CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'NotProfitable' END AS profit_category,
     lt.lateral_total,
     (
        SELECT max(ws2.ws_net_paid_inc_tax)
        FROM web_sales ws2
        WHERE ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk
     ) AS max_net_paid
   FROM web_sales ws
   RIGHT OUTER JOIN ship_mode sm
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN customer_address ca
     ON ws.ws_ship_addr_sk = ca.ca_address_sk
   LEFT JOIN web_site wsite
     ON ws.ws_web_site_sk = wsite.web_site_sk
   CROSS JOIN LATERAL (
     SELECT ws.ws_quantity * ws.ws_sales_price AS lateral_total
   ) lt
   WHERE EXISTS (
           SELECT 1
           FROM web_site ws2
           WHERE ws2.web_site_sk = ws.ws_web_site_sk
             AND ws2.web_city = 'Woodlawn'
         )
     AND wsite.web_gmt_offset = -8.00
     AND ca.ca_gmt_offset = -8.00
)
SELECT *
FROM (
   SELECT * FROM sub1
   UNION ALL
   SELECT * FROM sub2
) combined
ORDER BY profit_category DESC, lateral_total DESC
LIMIT 100
