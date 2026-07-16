SELECT
    i.i_category AS category,
    w.w_city AS city,
    COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    RANK() OVER (ORDER BY SUM(sr.sr_return_amt) DESC) AS category_city_rank
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE hd.hd_vehicle_count >= 2
  AND hd.hd_income_band_sk >= 3
  AND i.i_current_price > 20
  AND inv.inv_quantity_on_hand > 500
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY i.i_category, w.w_city
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 10
