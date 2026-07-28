WITH store_ret_agg AS (
    SELECT
        sr_item_sk,
        sr_store_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_return_quantity)    AS total_return_qty
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_return_amt_inc_tax > 50
    GROUP BY sr_item_sk, sr_store_sk
)

SELECT
    i.i_item_id,
    i.i_category,
    s.s_store_name,
    ca_bill.ca_state,
    ws.ws_net_profit,
    store_ret_agg.total_return_amt,
    RANK() OVER (PARTITION BY i.i_category ORDER BY store_ret_agg.total_return_amt DESC) AS category_return_rank,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS avg_promo_cost,
    (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk AND wr2.wr_return_quantity > 0) AS web_return_cnt
FROM web_sales ws
JOIN item i          ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p      ON ws.ws_promo_sk = p.p_promo_sk
JOIN warehouse w      ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_ret_agg    ON store_ret_agg.sr_item_sk = i.i_item_sk
JOIN store s          ON store_ret_agg.sr_store_sk = s.s_store_sk
JOIN web_returns wr  ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_item_sk = i.i_item_sk
WHERE i.i_category_id = 3
  AND p.p_channel_event = 'N'
  AND s.s_state = 'CA'
  AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2451919
  AND EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = i.i_item_sk AND sr.sr_store_sk = s.s_store_sk AND sr.sr_return_amt_inc_tax > 100)

UNION ALL

SELECT
    i.i_item_id,
    i.i_category,
    s.s_store_name,
    ca_bill.ca_state,
    ws.ws_net_profit,
    store_ret_agg.total_return_amt,
    RANK() OVER (PARTITION BY i.i_category ORDER BY store_ret_agg.total_return_amt DESC) AS category_return_rank,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS avg_promo_cost,
    (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk AND wr2.wr_return_quantity > 0) AS web_return_cnt
FROM web_sales ws
JOIN item i          ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p      ON ws.ws_promo_sk = p.p_promo_sk
JOIN warehouse w      ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_ret_agg    ON store_ret_agg.sr_item_sk = i.i_item_sk
JOIN store s          ON store_ret_agg.sr_store_sk = s.s_store_sk
JOIN web_returns wr  ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_item_sk = i.i_item_sk
WHERE i.i_category_id = 7
  AND p.p_channel_event = 'N'
  AND s.s_state = 'TX'
  AND ws.ws_sold_date_sk BETWEEN 2451920 AND 2451929
  AND EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = i.i_item_sk AND sr.sr_store_sk = s.s_store_sk AND sr.sr_return_amt_inc_tax > 100)

ORDER BY category_return_rank, total_return_amt DESC
LIMIT 100
