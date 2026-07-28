SELECT *
FROM (
   SELECT i.i_category AS category,
          'catalog' AS sales_channel,
          SUM(cs.cs_net_profit) AS total_profit
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE cs.cs_ext_sales_price > 500.00
     AND cs.cs_quantity > 1
   GROUP BY i.i_category

   UNION ALL

   SELECT i.i_category AS category,
          'web' AS sales_channel,
          SUM(ws.ws_net_profit) AS total_profit
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE ws.ws_ext_sales_price > 500.00
     AND ws.ws_quantity > 1
   GROUP BY i.i_category
) AS combined
ORDER BY total_profit DESC
LIMIT 20
