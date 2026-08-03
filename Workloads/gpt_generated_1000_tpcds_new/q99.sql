WITH sr_agg AS (
   SELECT sr_item_sk,
          SUM(sr_return_amt) AS total_return_amt,
          COUNT(*) AS return_cnt
   FROM store_returns
   GROUP BY sr_item_sk
),
ws_agg AS (
   SELECT ws_item_sk,
          SUM(ws_net_paid) AS total_net_paid,
          SUM(ws_ext_sales_price) AS total_sales_price,
          COUNT(DISTINCT ws_order_number) AS distinct_orders
   FROM web_sales
   GROUP BY ws_item_sk
)
SELECT
    i_ws.i_category,
    w.w_state,
    ca_bill.ca_state AS bill_state,
    SUM(ws_agg.total_net_paid)      AS agg_net_paid,
    SUM(sr_agg.total_return_amt)    AS agg_return_amt,
    SUM(ws_agg.total_sales_price) - SUM(sr_agg.total_return_amt) AS net_sales_minus_returns,
    COUNT(DISTINCT i_ws.i_item_id) AS distinct_items_sold,
    AVG(ws_agg.total_net_paid)      AS avg_net_paid_per_item
FROM sr_agg
JOIN store_returns sr_raw
     ON sr_raw.sr_item_sk = sr_agg.sr_item_sk                                 -- join 1
JOIN customer_address ca_ret
     ON sr_raw.sr_addr_sk = ca_ret.ca_address_sk                               -- join 2
JOIN item i_ret
     ON sr_raw.sr_item_sk = i_ret.i_item_sk                                     -- join 3
JOIN ws_agg
     ON ws_agg.ws_item_sk = i_ret.i_item_sk                                    -- join 4
JOIN web_sales ws_raw
     ON ws_raw.ws_item_sk = ws_agg.ws_item_sk                                 -- join 5
JOIN item i_ws
     ON ws_raw.ws_item_sk = i_ws.i_item_sk                                     -- join 6
JOIN customer_address ca_bill
     ON ws_raw.ws_bill_addr_sk = ca_bill.ca_address_sk                         -- join 7
JOIN customer_address ca_ship
     ON ws_raw.ws_ship_addr_sk = ca_ship.ca_address_sk                         -- join 8
JOIN warehouse w
     ON ws_raw.ws_warehouse_sk = w.w_warehouse_sk                               -- join 9
JOIN item i_extra
     ON ws_raw.ws_item_sk = i_extra.i_item_sk                                 -- join 10 (second alias of item)
JOIN customer_address ca_extra
     ON ws_raw.ws_bill_addr_sk = ca_extra.ca_address_sk                         -- join 11 (second alias of address)
WHERE ws_raw.ws_net_paid > (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2)   -- scalar subquery
  AND ws_raw.ws_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_brand_id = 8015002) -- IN subquery
  AND EXISTS (SELECT 1 FROM warehouse w2 WHERE w2.w_state = w.w_state AND w2.w_warehouse_sq_ft > 100000) -- EXISTS subquery
GROUP BY i_ws.i_category, w.w_state, ca_bill.ca_state
ORDER BY agg_net_paid DESC
LIMIT 100
