WITH avg_inventory AS (
    SELECT inv_item_sk, AVG(inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    s.s_store_name,
    s.s_city,
    s.s_state,
    t.t_hour,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS num_returns,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    AVG(ai.avg_qty_on_hand) AS avg_inventory_qty,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_active_count,
    ROUND(AVG(sr.sr_return_tax), 2) AS avg_return_tax
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN promotion p ON i.i_item_sk = p.p_item_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN avg_inventory ai ON i.i_item_sk = ai.inv_item_sk
WHERE i.i_category = 'Electronics'
  AND ca.ca_location_type = 'condo'
  AND hd.hd_vehicle_count >= 2
  AND p.p_discount_active = 'Y'
  AND t.t_hour BETWEEN 17 AND 23
  AND s.s_tax_percentage > 0.07
GROUP BY s.s_store_name, s.s_city, s.s_state, t.t_hour
HAVING SUM(sr.sr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 10
