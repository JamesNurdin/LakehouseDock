WITH aggregated_returns AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        i.i_item_id,
        i.i_product_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    INNER JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_amount > 50
      AND c.c_birth_month IN (1, 2, 5)
      AND w.w_zip IN ('59275', '19231')
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name,
        i.i_item_id,
        i.i_product_name
)
SELECT
    ar.w_warehouse_id,
    ar.w_warehouse_name,
    ar.i_item_id,
    ar.i_product_name,
    ar.total_net_loss,
    ar.return_count,
    ar.distinct_customers,
    ar.avg_return_amount,
    CASE WHEN ar.total_net_loss > 0 THEN 'Loss' ELSE 'No Loss' END AS loss_category,
    RANK() OVER (PARTITION BY ar.w_warehouse_id ORDER BY ar.total_net_loss DESC) AS loss_rank_warehouse
FROM aggregated_returns ar
ORDER BY loss_rank_warehouse ASC, total_net_loss DESC
LIMIT 100
