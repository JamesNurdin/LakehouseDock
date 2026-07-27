WITH promo_sales AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'Other' END AS promo_channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_quantity > 1
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM inventory i2
          WHERE i2.inv_item_sk = ws.ws_item_sk
            AND i2.inv_quantity_on_hand > 0
      )
    GROUP BY p.p_promo_id, d.d_year,
        CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'Other' END
)
SELECT
    ps.p_promo_id,
    ps.d_year,
    ps.promo_channel,
    ps.total_sales,
    ps.total_profit,
    ps.orders_cnt,
    CASE
        WHEN ps.total_profit / NULLIF(ps.total_sales, 0) > 0.2 THEN 'HighMargin'
        ELSE 'LowMargin'
    END AS profit_category,
    (SELECT AVG(total_sales) FROM promo_sales) AS avg_sales_all
FROM promo_sales ps
WHERE ps.total_sales > (SELECT AVG(total_sales) FROM promo_sales) * 1.2
ORDER BY ps.total_profit DESC
LIMIT 100
