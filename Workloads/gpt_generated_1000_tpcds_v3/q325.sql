WITH base AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        ws.ws_ext_ship_cost,
        ws.ws_net_profit,
        ws.ws_order_number,
        i.i_item_sk AS item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        i.i_category_id,
        i.i_brand_id,
        wp.wp_max_ad_count,
        wp.wp_link_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_category_id = 9
      AND i.i_brand_id = 294
      AND wp.wp_max_ad_count >= 2
      AND ws.ws_ext_ship_cost > 100
)
SELECT
    base.i_category,
    base.i_brand,
    s.s_state,
    CASE WHEN base.i_current_price > 100 THEN 'high' ELSE 'low' END AS price_category,
    COUNT(DISTINCT base.ws_order_number) AS order_cnt,
    SUM(base.ws_net_profit) AS total_net_profit,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(base.ws_ext_ship_cost) AS avg_ship_cost,
    (SELECT AVG(ws3.ws_net_profit) FROM web_sales ws3) AS overall_avg_profit
FROM base
JOIN store_returns sr ON sr.sr_item_sk = base.item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE s.s_state IN ('CA', 'TX')
  AND sr.sr_return_quantity > 0
  AND s.s_tax_percentage < 0.08
  AND base.wp_link_count > 10
GROUP BY base.i_category,
         base.i_brand,
         s.s_state,
         CASE WHEN base.i_current_price > 100 THEN 'high' ELSE 'low' END
ORDER BY total_net_profit DESC
LIMIT 50
