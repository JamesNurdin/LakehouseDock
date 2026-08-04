WITH promo_words AS (
    SELECT p.p_promo_sk,
           word
    FROM promotion p
    CROSS JOIN UNNEST(split(p.p_promo_name, ' ')) AS t(word)
),
diff_orders AS (
    SELECT cs_order_number AS order_num
    FROM catalog_sales
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
)
SELECT
    pw.word AS promo_word,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_count
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN promo_words pw
  ON p.p_promo_sk = pw.p_promo_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN (
    SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
) inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
  AND sr.sr_customer_sk = c.c_customer_sk
  AND sr.sr_hdemo_sk = hd_ship.hd_demo_sk
  AND sr.sr_return_time_sk = t.t_time_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
  AND ws.ws_bill_customer_sk = c.c_customer_sk
  AND ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
  AND wr.wr_order_number = ws.ws_order_number
  AND wr.wr_returned_time_sk = t.t_time_sk
JOIN time_dim t2
  ON wr.wr_returned_time_sk = t2.t_time_sk
WHERE cs.cs_order_number IN (SELECT order_num FROM diff_orders)
  AND cs.cs_order_number NOT IN (
        SELECT ws2.ws_order_number FROM web_sales ws2
    )
GROUP BY pw.word
ORDER BY total_profit DESC
LIMIT 100
