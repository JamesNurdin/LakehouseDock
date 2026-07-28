WITH sales_by_item AS (
  SELECT
    i.i_item_sk,
    i.i_brand,
    i.i_category,
    i.i_size,
    i.i_manager_id,
    i.i_manufact_id,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_qty,
    AVG(ws.ws_sales_price) AS avg_sales_price
  FROM web_sales ws
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  WHERE i.i_size IN ('large', 'medium')
    AND i.i_manager_id = 23
    AND i.i_manufact_id IN (167, 294)
    AND ws.ws_quantity > 5
    AND ws.ws_ext_wholesale_cost BETWEEN 1000 AND 5000
    AND ws.ws_ship_customer_sk NOT IN (7015489, 4105565)
  GROUP BY i.i_item_sk, i.i_brand, i.i_category, i.i_size, i.i_manager_id, i.i_manufact_id
)
SELECT
  s.i_brand,
  s.i_category,
  COUNT(*) AS num_items,
  AVG(s.total_profit) AS avg_profit_per_item,
  SUM(s.total_qty) AS total_quantity_sold
FROM sales_by_item s
WHERE s.avg_sales_price > (
        SELECT AVG(ws2.ws_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_quantity > 0
      )
  AND EXISTS (
        SELECT 1
        FROM web_sales ws3
        WHERE ws3.ws_item_sk = s.i_item_sk
          AND ws3.ws_ship_cdemo_sk = 30023
      )
GROUP BY s.i_brand, s.i_category
HAVING SUM(s.total_qty) > 1000
ORDER BY avg_profit_per_item DESC
LIMIT 10
