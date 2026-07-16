SELECT d.d_year,
       i.i_category,
       p.p_promo_name,
       SUM(ws.ws_net_paid) AS total_net_paid,
       COUNT(DISTINCT ws.ws_order_number) AS num_orders,
       (SELECT i2.i_brand FROM item i2 WHERE i2.i_item_sk = ws.ws_item_sk AND i2.i_brand = 'importoamalg #1                                   ') AS item_brand_filtered
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE d.d_year = 1906
  AND p.p_discount_active = 'N'
GROUP BY d.d_year, i.i_category, p.p_promo_name, ws.ws_item_sk
HAVING i.i_category = 'Men                                               '
