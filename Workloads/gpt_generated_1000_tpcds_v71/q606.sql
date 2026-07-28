/* goal: Identify ship modes associated with higher net loss returns, focusing on returns coming from street numbers in the 300‑599 range, ship mode IDs matching a specific pattern, and items priced above 100 with Red or Blue colors. */
WITH high_price_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_current_price > 100
      AND regexp_like(i_color, '^(Red|Blue)$')
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    regexp_extract(sm.sm_contract, '\\d+') AS contract_number,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount
FROM catalog_returns cr
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
  ON cr.cr_returning_addr_sk = ca.ca_address_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
WHERE regexp_like(ca.ca_street_number, '^[3-5][0-9]{2}$')
  AND sm.sm_ship_mode_id LIKE 'AAAAAAA%AA'
  AND cr.cr_item_sk IN (SELECT i_item_sk FROM high_price_items)
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    regexp_extract(sm.sm_contract, '\\d+')
ORDER BY total_net_loss DESC
LIMIT 10
