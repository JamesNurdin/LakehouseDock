WITH returned_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_refunded_cdemo_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_qty,
        AVG(cr.cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr.cr_return_quantity) > 10 THEN 'High' ELSE 'Low' END AS qty_level
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 10            -- predicate 1
      AND cr.cr_fee < 50                     -- predicate 2
      AND cr.cr_return_tax > 0.5             -- predicate 3
    GROUP BY cr.cr_warehouse_sk, cr.cr_refunded_cdemo_sk
),
warehouse_demo AS (
    SELECT
        w.w_warehouse_name,
        cd.cd_gender,
        agg.total_return_amount,
        agg.total_qty,
        agg.avg_fee,
        agg.return_cnt,
        agg.qty_level,
        CASE WHEN agg.total_return_amount > 1000 THEN 'BigLoss' ELSE 'SmallLoss' END AS loss_category
    FROM returned_agg agg
    JOIN warehouse w
      ON agg.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
      ON agg.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE w.w_state = 'CA'                         -- predicate 4
      AND cd.cd_purchase_estimate >= 3000          -- predicate 5
      AND w.w_suite_number = 'Suite R   '          -- predicate 6
)
SELECT
    w_warehouse_name,
    SUM(total_return_amount) AS warehouse_total_return,
    SUM(total_qty) AS warehouse_total_qty,
    AVG(avg_fee) AS warehouse_avg_fee,
    COUNT(*) AS demo_group_cnt,
    CASE WHEN SUM(total_return_amount) > 5000 THEN 'VeryHigh' ELSE 'Moderate' END AS warehouse_loss_category
FROM warehouse_demo
GROUP BY w_warehouse_name
HAVING SUM(total_qty) > 20
ORDER BY warehouse_total_return DESC
LIMIT 100
