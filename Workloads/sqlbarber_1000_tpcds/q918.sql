SELECT i.i_item_id,
       i.i_brand,
       i.i_item_sk,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
       (SELECT sr2.sr_return_amt
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
        ORDER BY sr2.sr_returned_date_sk DESC
        LIMIT 1) AS latest_return_amt
FROM item i
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
WHERE i.i_current_price > 5.07
  AND p.p_discount_active = 'N'
GROUP BY i.i_item_id, i.i_brand, i.i_item_sk
HAVING SUM(ws.ws_net_profit) > 1851.20
