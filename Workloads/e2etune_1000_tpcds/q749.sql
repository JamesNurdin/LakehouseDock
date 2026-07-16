WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM warehouse w
    JOIN inventory i
        ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_state
),
returns_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        cd.cd_education_status AS cd_education_status,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 500
      AND cr.cr_return_quantity >= 1
    GROUP BY cr.cr_warehouse_sk, cd.cd_education_status
),
joined AS (
    SELECT
        wi.w_warehouse_name,
        wi.w_state,
        ra.cd_education_status,
        ra.return_cnt,
        ra.total_return_amount,
        ra.total_net_loss,
        ra.avg_return_qty,
        wi.total_quantity_on_hand,
        ra.total_net_loss / NULLIF(wi.total_quantity_on_hand, 0) AS net_loss_per_inventory
    FROM warehouse_inventory wi
    JOIN returns_agg ra
        ON wi.w_warehouse_sk = ra.cr_warehouse_sk
    WHERE wi.total_quantity_on_hand > 0
)
SELECT
    j.w_warehouse_name,
    j.w_state,
    j.cd_education_status,
    j.return_cnt,
    j.total_return_amount,
    j.total_net_loss,
    j.avg_return_qty,
    j.total_quantity_on_hand,
    j.net_loss_per_inventory,
    RANK() OVER (PARTITION BY j.w_state ORDER BY j.total_net_loss DESC) AS state_warehouse_rank
FROM joined j
ORDER BY j.total_net_loss DESC
LIMIT 200
