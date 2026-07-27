WITH inv_summary AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_warehouse_sk IN (5, 6, 9)
      AND inv_quantity_on_hand > 0
      AND inv_item_sk IN (101416, 101413, 101438)
    GROUP BY inv_date_sk, inv_warehouse_sk, inv_item_sk
)
SELECT
    d.d_fy_year,
    i.inv_warehouse_sk,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    SUM(i.total_qty_on_hand) AS total_qty_on_hand,
    (
        SELECT AVG(cr2.cr_net_loss)
        FROM catalog_returns cr2
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_fy_year = d.d_fy_year
    ) AS avg_yearly_net_loss
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN inv_summary i
    ON i.inv_date_sk = d.d_date_sk
WHERE d.d_fy_year = 1905
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND d.d_day_name = 'Monday'
  AND d.d_holiday = 'N'
  AND cr.cr_net_loss > 100
  AND cr.cr_return_quantity >= 1
  AND cr.cr_returning_addr_sk = 3431573
GROUP BY GROUPING SETS (
    (d.d_fy_year, i.inv_warehouse_sk),
    (d.d_fy_year),
    (i.inv_warehouse_sk),
    ()
)
ORDER BY d.d_fy_year ASC NULLS LAST, i.inv_warehouse_sk ASC NULLS LAST
LIMIT 100
