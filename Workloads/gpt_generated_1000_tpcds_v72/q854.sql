WITH inv_summary AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY inv_item_sk
)
SELECT
    ws.ws_order_number,
    i1.i_item_id,
    i1.i_product_name,
    wp1.wp_url,
    hd_bill.hd_buy_potential AS bill_buy_potential,
    hd_ship.hd_buy_potential AS ship_buy_potential,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'POSITIVE'
        WHEN SUM(ws.ws_net_profit) = 0 THEN 'BREAK_EVEN'
        ELSE 'NEGATIVE'
    END AS profit_category,
    inv_sum.total_qty
FROM web_sales ws
JOIN item i1
  ON ws.ws_item_sk = i1.i_item_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp1
  ON ws.ws_web_page_sk = wp1.wp_web_page_sk
JOIN inv_summary inv_sum
  ON inv_sum.inv_item_sk = i1.i_item_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN item i3
  ON wr.wr_item_sk = i3.i_item_sk
JOIN household_demographics hd_refund
  ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN household_demographics hd_return
  ON wr.wr_returning_hdemo_sk = hd_return.hd_demo_sk
JOIN web_page wp2
  ON wr.wr_web_page_sk = wp2.wp_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_order_number = ws.ws_order_number
      AND wr2.wr_return_quantity > 0
)
  AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
GROUP BY
    ws.ws_order_number,
    i1.i_item_id,
    i1.i_product_name,
    wp1.wp_url,
    hd_bill.hd_buy_potential,
    hd_ship.hd_buy_potential,
    inv_sum.total_qty
ORDER BY total_sales DESC
LIMIT 100
