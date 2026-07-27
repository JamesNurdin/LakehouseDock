WITH item_promo AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        i.i_manager_id,
        p.p_promo_name,
        p.p_discount_active
    FROM tpcds.item i
    JOIN tpcds.promotion p ON p.p_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{2}')
      AND p.p_discount_active = 'Y'
)
SELECT
    ip.i_brand,
    regexp_extract(ip.i_product_name, '(\\w+)-\\w+', 1) AS product_prefix,
    sm.sm_carrier,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    AVG(ws.ws_coupon_amt) AS avg_coupon
FROM tpcds.web_sales ws
JOIN item_promo ip ON ws.ws_item_sk = ip.i_item_sk
JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_contract LIKE 'P%'
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr
        WHERE sr.sr_item_sk = ws.ws_item_sk
          AND sr.sr_return_quantity > 0
    )
GROUP BY
    ip.i_brand,
    regexp_extract(ip.i_product_name, '(\\w+)-\\w+', 1),
    sm.sm_carrier,
    ip.i_manager_id
HAVING SUM(ws.ws_net_profit) > (
        SELECT AVG(ws2.ws_net_profit) * 1.5
        FROM tpcds.web_sales ws2
        JOIN tpcds.item i2 ON ws2.ws_item_sk = i2.i_item_sk
        WHERE i2.i_manager_id = ip.i_manager_id
    )
ORDER BY total_net_profit DESC
LIMIT 100
