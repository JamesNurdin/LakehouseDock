WITH filtered_sales AS (
    SELECT
        cs.cs_net_profit,
        w.w_city,
        i.i_brand,
        i.i_item_desc,
        p.p_promo_name,
        sm.sm_contract,
        t.t_hour
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '(?i)\\bCO\\b')
      AND regexp_like(p.p_promo_name, '(?i)SAVE')
      AND sm.sm_contract LIKE 'A___%'
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    w_city,
    i_brand,
    SUM(cs_net_profit) AS total_profit,
    COUNT(*) AS num_orders
FROM filtered_sales
GROUP BY w_city, i_brand
ORDER BY total_profit DESC
LIMIT 100
