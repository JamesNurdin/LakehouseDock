SELECT
    w.w_warehouse_name,
    w.w_state,
    hd.hd_income_band_sk,
    t.t_shift,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
FROM catalog_returns cr
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE cr.cr_return_amount > 100
  AND cr.cr_return_tax > 20
  AND t.t_shift = 'Evening'
  AND hd.hd_buy_potential = 'HIGH'
GROUP BY w.w_warehouse_name, w.w_state, hd.hd_income_band_sk, t.t_shift
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
