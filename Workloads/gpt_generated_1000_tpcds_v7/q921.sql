/*
  Goal: Analyze profitability and return loss by product category and brand for high‑priced items that are in the 'Unknown' container and have substantial return shipping costs.
*/
SELECT
  i.i_category,
  i.i_brand,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  SUM(cs.cs_net_profit) AS total_net_profit,
  AVG(sr.sr_net_loss) AS avg_return_loss,
  SUM(sr.sr_return_amt) AS total_return_amount
FROM
  catalog_sales cs
JOIN
  item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN
  store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
WHERE
  i.i_class_id IN (2, 5, 9)
  AND i.i_container = 'Unknown'
  AND cs.cs_list_price > 100
  AND sr.sr_return_ship_cost > 500
GROUP BY
  i.i_category,
  i.i_brand
ORDER BY
  total_net_profit DESC
