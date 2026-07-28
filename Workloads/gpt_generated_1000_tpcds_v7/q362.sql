WITH inv_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT d.d_year,
       d.d_month_seq,
       t.t_hour,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_net_loss) AS total_net_loss,
       AVG(i.total_qty_on_hand) AS avg_inventory_qty
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN inv_agg i
  ON i.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND d.d_current_day = 'N'
  AND t.t_second IN (13, 7, 2)
  AND t.t_time_id = 'AAAAAAAALAAAAAAA'
  AND cr.cr_returning_customer_sk IN (3753188, 9416573)
  AND cr.cr_return_quantity > 0
  AND cr.cr_net_loss > 0
GROUP BY d.d_year, d.d_month_seq, t.t_hour
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 50
