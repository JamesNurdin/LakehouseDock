SELECT
    p.p_promo_name,
    ca.ca_country,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_quantity ELSE 0 END) AS total_return_qty,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_quantity) AS total_sold_qty,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_net_paid) / NULLIF(SUM(ws.ws_quantity), 0) AS avg_net_paid_per_item
FROM web_sales ws
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
WHERE p.p_discount_active = 'Y'
  AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2451919
  AND ca.ca_country IN ('United States', 'Canada')
GROUP BY p.p_promo_name, ca.ca_country
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
