WITH combined_sales AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        p.p_promo_id,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_promo_sk = p.p_promo_sk
    WHERE w.w_state = 'CA'
      AND w.w_city = 'Los Angeles'
      AND p.p_channel_radio = 'Y'
      AND cs.cs_quantity > 5
      AND ws.ws_quantity > 5
      AND cs.cs_ext_list_price > 1000
      AND ws.ws_ext_sales_price < 5000
    GROUP BY w.w_warehouse_id, w.w_city, w.w_state, p.p_promo_id, p.p_promo_name
)
SELECT
    p_promo_id,
    p_promo_name,
    SUM(catalog_profit + web_profit) AS total_combined_profit,
    AVG(catalog_profit + web_profit) AS avg_combined_profit_per_warehouse,
    COUNT(*) AS warehouse_count
FROM combined_sales
GROUP BY p_promo_id, p_promo_name
HAVING AVG(catalog_profit + web_profit) > 5000
ORDER BY total_combined_profit DESC
LIMIT 100
