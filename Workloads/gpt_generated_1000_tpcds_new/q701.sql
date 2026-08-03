WITH intersect_set AS (
        SELECT DISTINCT cr.cr_item_sk AS item_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 100.00
        INTERSECT
        SELECT wr.wr_item_sk
        FROM web_returns wr
        WHERE wr.wr_return_amt > 120.00
    )
SELECT
    cp.cp_department,
    sm.sm_type,
    w.w_state,
    ti.t_hour,
    i.i_brand,
    COUNT(DISTINCT cr.cr_order_number) AS orders_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    CASE
        WHEN SUM(cr.cr_return_quantity) > 10 THEN 'High Quantity'
        ELSE 'Normal Quantity'
    END AS quantity_category,
    (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
    ) AS total_web_return_amt
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN time_dim ti ON cr.cr_returned_time_sk = ti.t_time_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_time_sk = ti.t_time_sk
WHERE cp.cp_department = 'Home'
  AND sm.sm_type = 'NEXT DAY'
  AND w.w_state = 'CA'
  AND ti.t_hour BETWEEN 9 AND 17
  AND i.i_item_sk IN (SELECT item_sk FROM intersect_set)
  AND EXISTS (
        SELECT 1
        FROM web_returns wr3
        WHERE wr3.wr_item_sk = i.i_item_sk
          AND wr3.wr_return_amt > 200.00
    )
GROUP BY cp.cp_department, sm.sm_type, w.w_state, ti.t_hour, i.i_brand, i.i_item_sk
ORDER BY total_net_loss DESC
LIMIT 100
