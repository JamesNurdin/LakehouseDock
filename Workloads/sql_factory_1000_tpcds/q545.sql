SELECT i.i_category,
       COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
       COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_ext_sales_price) / NULLIF(COUNT(DISTINCT i.i_item_sk),1) AS sales_per_item,
       PERCENT_RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) ASC) AS sales_percentile
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_category IN ('Electronics','Clothing')
  AND i.i_brand IS NOT NULL
GROUP BY i.i_category
ORDER BY sales_percentile DESC
LIMIT 3
