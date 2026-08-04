/*
  Goal: Identify return orders with their profit/loss status, combining data from warehouse returns (full outer join) and California call‑center returns, while excluding orders that appear only in the call‑center set (using EXCEPT). Results are ordered and limited to the first 100 rows.
*/
WITH full_join AS (
    SELECT
        cr.cr_order_number AS order_id,
        cr.cr_return_amount,
        w.w_country
    FROM catalog_returns cr
    FULL OUTER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States' OR w.w_country IS NULL
),
call_center_ret AS (
    SELECT
        cr.cr_order_number AS order_id,
        cr.cr_return_amount,
        cc.cc_state
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'
),
exclusive_orders AS (
    SELECT order_id FROM call_center_ret
    EXCEPT
    SELECT order_id FROM full_join
)
SELECT
    fj.order_id,
    CASE WHEN fj.cr_return_amount > 0 THEN 'Profit' ELSE 'Loss' END AS return_status,
    fj.w_country
FROM full_join fj
WHERE fj.order_id NOT IN (SELECT order_id FROM exclusive_orders)
UNION ALL
SELECT
    ccr.order_id,
    CASE WHEN ccr.cr_return_amount > 0 THEN 'Profit' ELSE 'Loss' END AS return_status,
    NULL AS w_country
FROM call_center_ret ccr
WHERE ccr.order_id IN (SELECT order_id FROM exclusive_orders)
ORDER BY order_id
OFFSET 0 FETCH NEXT 100 ROWS ONLY
