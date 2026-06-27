WITH catalog_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        sum(cs.cs_net_profit) AS catalog_net_profit,
        sum(cs.cs_ext_sales_price) AS catalog_sales_amount
    FROM catalog_sales cs
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
),
web_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        sum(ws.ws_net_profit) AS web_net_profit,
        sum(ws.ws_ext_sales_price) AS web_sales_amount
    FROM web_sales ws
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
)
SELECT
    COALESCE(ca.sm_ship_mode_id, wa.sm_ship_mode_id) AS ship_mode_id,
    COALESCE(ca.sm_type, wa.sm_type) AS ship_mode_type,
    ca.catalog_net_profit,
    wa.web_net_profit,
    ca.catalog_net_profit - wa.web_net_profit AS profit_diff,
    ca.catalog_sales_amount,
    wa.web_sales_amount
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
  ON ca.sm_ship_mode_id = wa.sm_ship_mode_id
 AND ca.sm_type = wa.sm_type
ORDER BY ship_mode_id
