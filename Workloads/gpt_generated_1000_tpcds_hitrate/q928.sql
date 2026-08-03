WITH returns_agg AS (
    SELECT
        cr.cr_warehouse_sk AS w_warehouse_sk,
        cr.cr_reason_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        MAX(cr.cr_returned_date_sk) AS max_return_date_sk
    FROM catalog_returns cr
    WHERE cr.cr_fee > 50
      AND cr.cr_return_amount BETWEEN 20 AND 1500
      AND cr.cr_reversed_charge < 100
      AND cr.cr_reason_sk IN (
            SELECT r.r_reason_sk
            FROM reason r
            WHERE r.r_reason_id = 'AAAAAAAAGAAAAAAA'
        )
    GROUP BY cr.cr_warehouse_sk, cr.cr_reason_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    r.r_reason_desc,
    ra.total_return_amount,
    ra.total_net_loss,
    CASE WHEN ra.total_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag,
    inv.inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY ra.total_return_amount DESC) AS rn_return_rank,
    SUM(ra.total_return_amount) OVER (
        PARTITION BY w.w_warehouse_id
        ORDER BY ra.total_return_amount
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_return_sum
FROM returns_agg ra
INNER JOIN warehouse w
    ON ra.w_warehouse_sk = w.w_warehouse_sk
INNER JOIN reason r
    ON ra.cr_reason_sk = r.r_reason_sk
INNER JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_street_type IN ('Parkway', 'Ave')
  AND w.w_zip = '33604'
  AND inv.inv_quantity_on_hand > 0
  AND r.r_reason_id <> 'AAAAAAAADBAAAAAA'
  AND w.w_state = 'TX'
ORDER BY ra.total_return_amount DESC
LIMIT 100
