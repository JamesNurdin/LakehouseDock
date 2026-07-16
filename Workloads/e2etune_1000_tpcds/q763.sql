SELECT i.i_category,
       date_trunc('month', date_add('day', cr.cr_returned_date_sk, date '1970-01-01')) AS return_month,
       SUM(cr.cr_net_loss) AS total_net_loss,
       SUM(cr.cr_return_quantity) AS total_return_qty,
       AVG(p.p_cost) AS avg_promo_cost,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
       RANK() OVER (PARTITION BY date_trunc('month', date_add('day', cr.cr_returned_date_sk, date '1970-01-01')) ORDER BY SUM(cr.cr_net_loss) DESC) AS month_category_rank
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
WHERE cr.cr_warehouse_sk = 13
  AND cr.cr_return_tax > 100
  AND p.p_discount_active = 'Y'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY i.i_category,
         date_trunc('month', date_add('day', cr.cr_returned_date_sk, date '1970-01-01'))
HAVING SUM(cr.cr_net_loss) > 500
ORDER BY total_net_loss DESC
LIMIT 50
