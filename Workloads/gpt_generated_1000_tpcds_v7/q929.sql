WITH return_warehouse_summary AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_fee) AS avg_fee
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE cs.cs_ext_tax > 50
      AND cs.cs_ext_ship_cost BETWEEN 100 AND 1500
      AND cr.cr_return_amount > 100
      AND cr.cr_fee > 20
      AND w.w_state = 'CA'
    GROUP BY w.w_warehouse_name, r.r_reason_desc
)
SELECT
    warehouse_name,
    AVG(total_net_loss) AS avg_total_loss_per_reason,
    SUM(return_cnt) AS total_returns,
    AVG(avg_fee) AS avg_fee_across_reasons
FROM return_warehouse_summary
GROUP BY warehouse_name
HAVING AVG(total_net_loss) > 500
ORDER BY avg_total_loss_per_reason DESC
LIMIT 10
