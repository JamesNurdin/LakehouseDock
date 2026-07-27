WITH agg AS (
    SELECT
        w.w_warehouse_name,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cs.cs_net_paid) AS total_sales_paid,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 20
      AND cr.cr_refunded_cash >= 100
      AND i.i_manufact = 'esecallypri'
    GROUP BY w.w_warehouse_name, r.r_reason_desc
)
SELECT
    w_warehouse_name,
    r_reason_desc,
    total_return_amount,
    total_sales_paid,
    return_cnt,
    total_return_amount / NULLIF(total_sales_paid, 0) AS return_to_sales_ratio
FROM agg
WHERE total_return_amount > 500
  AND total_sales_paid > 0
  AND (total_return_amount / NULLIF(total_sales_paid, 0)) > 0.05
ORDER BY return_to_sales_ratio DESC
LIMIT 100
