SELECT
  I.i_item_id,
  I.i_product_name,
  P.p_promo_name,
  CS.cs_order_number,
  CS.cs_quantity,
  CS.cs_net_profit,
  SUM(CS.cs_ext_sales_price) OVER (PARTITION BY I.i_item_id ORDER BY CS.cs_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales_price,
  RANK() OVER (PARTITION BY P.p_promo_name ORDER BY CS.cs_net_profit DESC) AS profit_rank_by_promo,
  CASE WHEN WS.ws_coupon_amt > 500 THEN 'HIGH' ELSE 'LOW' END AS coupon_level,
  WR.wr_net_loss
FROM catalog_sales CS
JOIN item I ON CS.cs_item_sk = I.i_item_sk
JOIN promotion P ON CS.cs_promo_sk = P.p_promo_sk
JOIN store_sales SS ON SS.ss_item_sk = I.i_item_sk
JOIN warehouse W ON CS.cs_warehouse_sk = W.w_warehouse_sk
JOIN web_sales WS ON WS.ws_item_sk = I.i_item_sk
JOIN web_returns WR ON WR.wr_item_sk = I.i_item_sk AND WR.wr_order_number = WS.ws_order_number
WHERE
  CS.cs_quantity > 5
  AND CS.cs_sales_price BETWEEN 100 AND 500
  AND I.i_class_id IN (1, 4, 9)
  AND P.p_discount_active = 'Y'
  AND SS.ss_wholesale_cost < 30
  AND WS.ws_coupon_amt > 100
ORDER BY profit_rank_by_promo, I.i_item_id
LIMIT 100
