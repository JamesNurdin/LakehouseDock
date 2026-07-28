WITH base AS (
    SELECT
        i.i_category,
        wp.wp_type,
        (cs.cs_net_profit + ws.ws_net_profit) AS total_net_profit,
        cs.cs_quantity,
        ws.ws_quantity,
        i.i_wholesale_cost,
        ws.ws_ext_ship_cost,
        ws.ws_promo_sk,
        CASE WHEN (cs.cs_net_profit + ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY (cs.cs_net_profit + ws.ws_net_profit) DESC) AS rn_category
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_wholesale_cost > 5
      AND ws.ws_ext_ship_cost < 2000
      AND wp.wp_max_ad_count >= 2
      AND i.i_rec_end_date > DATE '2000-01-01'
)
SELECT
    i_category,
    wp_type,
    SUM(total_net_profit) AS sum_profit,
    AVG(total_net_profit) AS avg_profit,
    COUNT(*) AS cnt,
    MAX(CASE WHEN profit_flag = 'Profitable' THEN total_net_profit END) AS max_profitable_profit
FROM base
WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = base.ws_promo_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY GROUPING SETS (
        (i_category, wp_type),
        (i_category),
        (wp_type),
        ()
    )
HAVING SUM(total_net_profit) > 0
ORDER BY sum_profit DESC
LIMIT 100
