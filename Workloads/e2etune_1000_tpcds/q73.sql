SELECT
    p.p_promo_name,
    r.r_reason_desc,
    i.inv_warehouse_sk,
    i.inv_date_sk,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(p.p_cost) AS total_promo_cost
FROM web_returns wr
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN inventory i
    ON i.inv_item_sk = wr.wr_item_sk
   AND i.inv_date_sk = wr.wr_returned_date_sk
JOIN promotion p
    ON p.p_item_sk = wr.wr_item_sk
   AND p.p_start_date_sk <= wr.wr_returned_date_sk
   AND p.p_end_date_sk >= wr.wr_returned_date_sk
WHERE wr.wr_return_amt > 0
  AND i.inv_quantity_on_hand IS NOT NULL
GROUP BY
    p.p_promo_name,
    r.r_reason_desc,
    i.inv_warehouse_sk,
    i.inv_date_sk
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
