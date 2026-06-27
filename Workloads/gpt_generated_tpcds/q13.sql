WITH ws_agg AS (
    SELECT
        ws_promo_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    p.p_channel_email,
    ws_agg.total_net_profit,
    ws_agg.total_sales,
    ws_agg.total_quantity,
    ws_agg.total_discount,
    ws_agg.total_discount / NULLIF(ws_agg.total_quantity, 0) AS avg_discount_per_item
FROM promotion p
JOIN ws_agg
    ON ws_agg.ws_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
  AND p.p_channel_email = 'Y'
ORDER BY ws_agg.total_net_profit DESC
LIMIT 100
