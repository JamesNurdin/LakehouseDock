WITH sales_demo AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_warehouse_sk,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    i.i_product_name,
    w.w_warehouse_name,
    inv.inv_quantity_on_hand
  FROM catalog_sales cs
  JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_ext_sales_price > 100
)
SELECT
  sd.i_product_name,
  sd.w_warehouse_name,
  sd.bill_gender,
  sd.ship_gender,
  SUM(sd.cs_ext_sales_price) AS total_sales_price,
  SUM(sd.cs_net_profit) AS total_net_profit,
  COALESCE(SUM(sd.inv_quantity_on_hand), 0) AS total_quantity_on_hand,
  AVG(
    (SELECT AVG(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_item_sk = sd.cs_item_sk)
  ) AS avg_return_amount_per_item
FROM sales_demo sd
JOIN web_returns wr
  ON wr.wr_item_sk = sd.cs_item_sk
JOIN customer_demographics cd_refund
  ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer_demographics cd_returning
  ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN inventory inv2
  ON inv2.inv_item_sk = sd.cs_item_sk
JOIN warehouse w_inv
  ON inv2.inv_warehouse_sk = w_inv.w_warehouse_sk
GROUP BY
  sd.i_product_name,
  sd.w_warehouse_name,
  sd.bill_gender,
  sd.ship_gender
ORDER BY total_net_profit DESC
LIMIT 100
