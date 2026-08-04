SELECT
    i.i_item_id,
    p.p_promo_name,
    SUM(ss.ss_ext_sales_price) AS total_sales
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
  AND ss.ss_ext_sales_price > 2000
GROUP BY i.i_item_id, p.p_promo_name

UNION

SELECT
    i.i_item_id,
    p.p_promo_name,
    SUM(ws.ws_ext_sales_price) AS total_sales
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
  AND ws.ws_ext_sales_price > 2000
GROUP BY i.i_item_id, p.p_promo_name

ORDER BY total_sales DESC
LIMIT 100
