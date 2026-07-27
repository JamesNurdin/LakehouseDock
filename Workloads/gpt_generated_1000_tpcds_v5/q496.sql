WITH distinct_promos AS (
    SELECT DISTINCT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_channel_catalog,
        p.p_discount_active
    FROM promotion p
    WHERE p.p_channel_catalog = 'Y'
      AND p.p_discount_active = 'Y'
),
sales_agg AS (
    SELECT
        dp.p_promo_id,
        hd_cs.hd_demo_sk,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN distinct_promos dp ON cs.cs_promo_sk = dp.p_promo_sk
    JOIN household_demographics hd_cs ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN web_sales ws ON ws.ws_promo_sk = dp.p_promo_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 1000
      AND ws.ws_net_paid_inc_ship_tax > 1000
      AND hd_cs.hd_vehicle_count >= 2
      AND hd_ws.hd_vehicle_count >= 2
      AND cs.cs_quantity BETWEEN 1 AND 10
      AND ws.ws_quantity BETWEEN 1 AND 5
    GROUP BY dp.p_promo_id, hd_cs.hd_demo_sk
)
SELECT
    promo_id,
    AVG(total_profit) AS avg_total_profit,
    SUM(total_orders) AS total_orders
FROM (
    SELECT
        p_promo_id AS promo_id,
        (catalog_profit + web_profit) AS total_profit,
        (catalog_orders + web_orders) AS total_orders
    FROM sales_agg
) agg
GROUP BY promo_id
HAVING AVG(total_profit) > 5000
ORDER BY avg_total_profit DESC
LIMIT 100
