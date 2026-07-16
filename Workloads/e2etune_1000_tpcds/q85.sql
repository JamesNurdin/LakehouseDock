SELECT
    cc.cc_manager,
    s.s_state,
    p.p_promo_name,
    inv.inv_date_sk AS inventory_date_sk,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    COUNT(DISTINCT wr.wr_order_number) AS unique_orders
FROM call_center cc
JOIN store s
    ON cc.cc_mkt_id = s.s_market_id
JOIN promotion p
    ON cc.cc_open_date_sk = p.p_start_date_sk
JOIN inventory inv
    ON inv.inv_item_sk = p.p_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = inv.inv_item_sk
    AND wr.wr_returned_date_sk = inv.inv_date_sk
WHERE cc.cc_manager IN ('Bob Belcher', 'Felipe Perkins')
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND inv.inv_quantity_on_hand > 0
  AND wr.wr_return_amt > 0
GROUP BY
    cc.cc_manager,
    s.s_state,
    p.p_promo_name,
    inv.inv_date_sk
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_return_amt DESC
LIMIT 100
