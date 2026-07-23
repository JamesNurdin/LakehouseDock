SELECT
    wh.w_warehouse_id,
    wh.w_city,
    dd.d_year,
    COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
    COUNT(DISTINCT hd.hd_demo_sk) AS distinct_households,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(inv.inv_quantity_on_hand) + SUM(inv2.inv_quantity_on_hand) + SUM(inv3.inv_quantity_on_hand) AS total_quantity_on_hand,
    CASE
        WHEN SUM(sr.sr_net_loss) > 5000 THEN 'Very High'
        WHEN SUM(sr.sr_net_loss) > 2000 THEN 'High'
        WHEN SUM(sr.sr_net_loss) > 500 THEN 'Medium'
        ELSE 'Low'
    END AS net_loss_category
FROM store_returns sr
JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv ON inv.inv_date_sk = dd.d_date_sk
JOIN warehouse wh ON inv.inv_warehouse_sk = wh.w_warehouse_sk
JOIN inventory inv2 ON inv2.inv_date_sk = dd.d_date_sk
JOIN warehouse wh2 ON inv2.inv_warehouse_sk = wh2.w_warehouse_sk
JOIN inventory inv3 ON inv3.inv_date_sk = dd.d_date_sk
JOIN warehouse wh3 ON inv3.inv_warehouse_sk = wh3.w_warehouse_sk
WHERE ib.ib_lower_bound >= 150000
  AND dd.d_year BETWEEN 2000 AND 2002
  AND sr.sr_return_quantity > 0
GROUP BY wh.w_warehouse_id, wh.w_city, dd.d_year
ORDER BY total_net_loss DESC
LIMIT 100
