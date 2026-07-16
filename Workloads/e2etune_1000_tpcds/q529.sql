SELECT
    wsi.web_name AS site_name,
    wp.wp_type AS page_type,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_quantity_returned,
    CASE WHEN SUM(ws.ws_quantity) = 0 THEN 0
         ELSE SUM(COALESCE(wr.wr_return_quantity, 0)) / SUM(ws.ws_quantity) END AS return_rate,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) AS net_profit_after_returns,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    RANK() OVER (ORDER BY (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) DESC) AS profit_rank
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_web_page_sk = wr.wr_web_page_sk
WHERE ws.ws_sold_date_sk BETWEEN 2451000 AND 2452000
  AND wp.wp_type IN ('product', 'category')
  AND ws.ws_quantity > 0
GROUP BY wsi.web_name, wp.wp_type
HAVING SUM(ws.ws_quantity) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
