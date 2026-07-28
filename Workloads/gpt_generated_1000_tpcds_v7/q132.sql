/*
Goal: Compute the combined net profit from catalog and web sales for each warehouse, rank warehouses by total profit, and categorize volume. The query joins all eight selected tables, applies multiple demographic, promotion, and geographic filters, uses LEFT OUTER JOINs, a window function (RANK), a CASE expression, and a scalar subquery for average active promotion cost. Results are limited to the top 100 warehouses.
*/
WITH catalog_agg AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        SUM(cs.cs_net_profit) AS catalog_profit,
        COUNT(*) AS catalog_orders,
        MAX(cc.cc_name) AS call_center_name
    FROM catalog_sales cs
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_channel_press = 'N'
      AND cc.cc_state = 'CA'
      AND hd.hd_buy_potential = '0-500'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY cs.cs_warehouse_sk
),
web_agg AS (
    SELECT
        ws.ws_warehouse_sk AS warehouse_sk,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(*) AS web_orders,
        MAX(wp.wp_type) AS web_page_type
    FROM web_sales ws
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_channel_press = 'N'
      AND wp.wp_url LIKE 'http%'
      AND hd.hd_vehicle_count >= 0
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY ws.ws_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_gmt_offset,
    COALESCE(ca.catalog_profit, 0) AS catalog_profit,
    COALESCE(wa.web_profit, 0) AS web_profit,
    (COALESCE(ca.catalog_profit, 0) + COALESCE(wa.web_profit, 0)) AS total_profit,
    RANK() OVER (ORDER BY (COALESCE(ca.catalog_profit, 0) + COALESCE(wa.web_profit, 0)) DESC) AS profit_rank,
    CASE
        WHEN COALESCE(ca.catalog_orders, 0) + COALESCE(wa.web_orders, 0) > 1000 THEN 'High Volume'
        ELSE 'Normal Volume'
    END AS volume_category,
    (
        SELECT AVG(p_sub.p_cost)
        FROM promotion p_sub
        WHERE p_sub.p_discount_active = 'Y'
          AND p_sub.p_channel_press = 'N'
    ) AS avg_active_promo_cost
FROM warehouse w
LEFT JOIN catalog_agg ca
    ON w.w_warehouse_sk = ca.warehouse_sk
LEFT JOIN web_agg wa
    ON w.w_warehouse_sk = wa.warehouse_sk
WHERE w.w_gmt_offset = -5.00
  AND w.w_state = 'CA'
  AND w.w_city IS NOT NULL
  AND w.w_zip IS NOT NULL
ORDER BY total_profit DESC
LIMIT 100
