WITH cs AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_net_profit,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN promotion p1 ON cs.cs_promo_sk = p1.p_promo_sk
    JOIN warehouse wh1 ON cs.cs_warehouse_sk = wh1.w_warehouse_sk
),
ws AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN warehouse wh2 ON ws.ws_warehouse_sk = wh2.w_warehouse_sk
),
union_sales AS (
    SELECT
        'catalog' AS src,
        cs_warehouse_sk AS warehouse_sk,
        cs_promo_sk AS promo_sk,
        SUM(cs_net_profit) AS net_profit
    FROM cs
    GROUP BY cs_warehouse_sk, cs_promo_sk
    UNION ALL
    SELECT
        'web' AS src,
        ws_warehouse_sk AS warehouse_sk,
        ws_promo_sk AS promo_sk,
        SUM(ws_net_profit) AS net_profit
    FROM ws
    GROUP BY ws_warehouse_sk, ws_promo_sk
),
inventory_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
promo_details AS (
    SELECT
        p_promo_sk,
        CASE WHEN p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
    FROM promotion
)
SELECT
    u.src,
    wh.w_warehouse_name,
    pd.promo_status,
    u.net_profit,
    CASE WHEN u.net_profit > (SELECT AVG(net_profit) FROM union_sales) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category,
    inv.total_on_hand,
    ROW_NUMBER() OVER (PARTITION BY wh.w_warehouse_sk ORDER BY u.net_profit DESC) AS profit_rank
FROM union_sales u
JOIN warehouse wh ON u.warehouse_sk = wh.w_warehouse_sk
JOIN promo_details pd ON u.promo_sk = pd.p_promo_sk
JOIN inventory_agg inv ON wh.w_warehouse_sk = inv.inv_warehouse_sk
WHERE EXISTS (
    SELECT 1 FROM inventory i WHERE i.inv_warehouse_sk = wh.w_warehouse_sk AND i.inv_quantity_on_hand > 0
)
ORDER BY u.net_profit DESC
LIMIT 100
