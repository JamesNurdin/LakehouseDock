WITH base AS (
   SELECT
        cc.cc_call_center_id,
        cc.cc_market_manager,
        cc.cc_tax_percentage,
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        sm.sm_type,
        sm.sm_contract,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_item_sk,
        ws.ws_wholesale_cost,
        web.web_site_id,
        web.web_name,
        web.web_market_manager,
        web.web_tax_percentage
   FROM catalog_sales cs
   JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_sales ws
        ON cs.cs_ship_mode_sk = ws.ws_ship_mode_sk
   JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
   WHERE cc.cc_tax_percentage > 0.05
     AND cc.cc_market_manager LIKE '%manager%'
     AND sm.sm_type IN ('EXPRESS', 'NEXT DAY')
     AND sm.sm_contract NOT LIKE 'A5B%'
     AND ws.ws_wholesale_cost BETWEEN 30 AND 80
     AND ws.ws_item_sk IN (269809, 198523, 211787)
),
distinct_sales AS (
   SELECT DISTINCT
        cc_call_center_id,
        web_site_id,
        sm_type,
        cs_order_number,
        cs_net_profit,
        cs_quantity,
        ws_order_number,
        ws_net_profit,
        ws_quantity
   FROM base
),
agg AS (
   SELECT
        ds.cc_call_center_id,
        ds.web_site_id,
        ds.sm_type,
        SUM(ds.cs_net_profit + ds.ws_net_profit) AS total_net_profit,
        SUM(ds.cs_quantity + ds.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ds.cs_order_number) AS distinct_cs_orders,
        COUNT(DISTINCT ds.ws_order_number) AS distinct_ws_orders
   FROM distinct_sales ds
   GROUP BY ds.cc_call_center_id, ds.web_site_id, ds.sm_type
)
SELECT
    a.cc_call_center_id,
    a.web_site_id,
    a.sm_type,
    a.total_net_profit,
    a.total_quantity,
    a.distinct_cs_orders,
    a.distinct_ws_orders,
    RANK() OVER (PARTITION BY a.sm_type ORDER BY a.total_net_profit DESC) AS profit_rank_by_ship_mode,
    SUM(a.total_net_profit) OVER (
        PARTITION BY a.cc_call_center_id
        ORDER BY a.total_net_profit
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_by_center
FROM agg a
WHERE a.total_quantity > 100
  AND a.distinct_cs_orders >= 5
  AND a.distinct_ws_orders >= 5
ORDER BY a.total_net_profit DESC
LIMIT 100
