WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 1
      AND ws.ws_sales_price BETWEEN 10 AND 500
      AND ws.ws_ext_discount_amt < 50
      AND ws.ws_net_profit > -100
      AND ws.ws_bill_hdemo_sk IS NOT NULL
      AND ws.ws_ship_hdemo_sk IS NOT NULL
)
SELECT
    i.i_item_id,
    i.i_brand,
    i.i_category,
    hd_bill.hd_buy_potential,
    SUM(fs.ws_quantity) AS total_quantity_sold,
    SUM(fs.ws_net_profit) AS total_net_profit,
    AVG(fs.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT fs.ws_order_number) AS distinct_orders,
    CASE
        WHEN SUM(fs.ws_net_profit) > 10000 THEN 'High'
        WHEN SUM(fs.ws_net_profit) BETWEEN 0 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (SELECT AVG(ws_sub.ws_net_profit)
     FROM web_sales ws_sub
     WHERE ws_sub.ws_item_sk = i.i_item_sk) AS avg_item_profit,
    COUNT(CASE WHEN inv.inv_quantity_on_hand > 200 THEN 1 END) AS warehouses_with_high_stock
FROM filtered_sales fs
JOIN item i
  ON fs.ws_item_sk = i.i_item_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN household_demographics hd_bill
  ON fs.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON fs.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE i.i_wholesale_cost > 0.5
  AND i.i_size = 'medium'
  AND i.i_manufact = 'callyable'
  AND hd_bill.hd_dep_count <= 5
  AND inv.inv_quantity_on_hand >= 100
  AND inv.inv_date_sk = 2450955
GROUP BY
    i.i_item_id,
    i.i_brand,
    i.i_category,
    hd_bill.hd_buy_potential,
    i.i_item_sk
ORDER BY total_net_profit DESC
LIMIT 100
