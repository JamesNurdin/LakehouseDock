WITH first_part AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Medium' END AS loss_category,
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
        ) AS avg_return_amount_warehouse
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_fee > 20
      AND cr.cr_return_amount > 100
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr3
          WHERE cr3.cr_warehouse_sk = w.w_warehouse_sk
            AND cr3.cr_return_quantity > 5
      )
    GROUP BY w.w_warehouse_id, w.w_city, w.w_warehouse_sk
),
second_part AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Medium' END AS loss_category,
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
        ) AS avg_return_amount_warehouse
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_store_credit > 500
      AND w.w_state = 'CA'
      AND cr.cr_fee <= 20
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr3
          WHERE cr3.cr_warehouse_sk = w.w_warehouse_sk
            AND cr3.cr_return_quantity > 5
      )
    GROUP BY w.w_warehouse_id, w.w_city, w.w_warehouse_sk
)
SELECT
    w_warehouse_id,
    w_city,
    total_return_amount,
    total_net_loss,
    loss_category,
    avg_return_amount_warehouse
FROM first_part
UNION ALL
SELECT
    w_warehouse_id,
    w_city,
    total_return_amount,
    total_net_loss,
    loss_category,
    avg_return_amount_warehouse
FROM second_part
ORDER BY total_net_loss DESC
LIMIT 100
