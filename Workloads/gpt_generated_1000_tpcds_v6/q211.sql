WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_net_loss,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_order_number,
        r.r_reason_desc,
        w.w_warehouse_name,
        w.w_state,
        CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 50
      AND cr.cr_return_quantity >= 2
      AND cr.cr_fee BETWEEN 20 AND 80
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND (w.w_state = 'CA' OR w.w_state IS NULL)
)
SELECT
    loss_category,
    r_reason_desc,
    COALESCE(w_warehouse_name, 'UNKNOWN') AS warehouse_name,
    SUM(cr_return_amount) OVER (
        PARTITION BY loss_category
        ORDER BY cr_return_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_amount,
    ROW_NUMBER() OVER (
        PARTITION BY loss_category
        ORDER BY cr_return_amount DESC
    ) AS rn,
    COUNT(*) OVER (PARTITION BY loss_category) AS cnt_per_category
FROM filtered
ORDER BY loss_category, rn
LIMIT 100
