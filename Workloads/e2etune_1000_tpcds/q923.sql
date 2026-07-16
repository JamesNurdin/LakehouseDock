WITH catalog_agg AS (
    SELECT cs.cs_ship_mode_sk,
           SUM(cs.cs_net_profit) AS catalog_net_profit,
           SUM(cs.cs_ext_sales_price) AS catalog_sales,
           COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'TN'
      AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2451200
    GROUP BY cs.cs_ship_mode_sk
),
web_agg AS (
    SELECT ws.ws_ship_mode_sk,
           SUM(ws.ws_net_profit) AS web_net_profit,
           SUM(ws.ws_ext_sales_price) AS web_sales,
           COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_state = 'TN'
      AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2451200
    GROUP BY ws.ws_ship_mode_sk
)
SELECT sm.sm_type,
       COALESCE(ca.catalog_net_profit, 0) AS catalog_net_profit,
       COALESCE(wa.web_net_profit, 0) AS web_net_profit,
       CASE WHEN ca.catalog_net_profit > 0
            THEN wa.web_net_profit / ca.catalog_net_profit
            ELSE NULL
       END AS web_to_catalog_profit_ratio,
       COALESCE(ca.catalog_orders, 0) AS catalog_orders,
       COALESCE(wa.web_orders, 0) AS web_orders,
       RANK() OVER (ORDER BY CASE WHEN ca.catalog_net_profit > 0
                                 THEN wa.web_net_profit / ca.catalog_net_profit
                                 ELSE 0
                            END DESC) AS profit_ratio_rank
FROM ship_mode sm
LEFT JOIN catalog_agg ca
  ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_agg wa
  ON wa.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type IN ('AIR', 'RAIL', 'TRUCK')
ORDER BY profit_ratio_rank
LIMIT 20
