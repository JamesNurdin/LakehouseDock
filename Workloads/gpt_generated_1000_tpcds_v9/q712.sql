WITH combined_returns AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_class_id AS class_id,
        i.i_manager_id AS manager_id,
        i.i_wholesale_cost AS wholesale_cost,
        c.c_customer_id AS customer_id,
        c.c_birth_day AS birth_day,
        cr.cr_net_loss AS net_loss,
        'catalog' AS return_type,
        r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE i.i_class_id IN (1, 3, 6)
      AND i.i_manager_id NOT IN (23)
      AND i.i_wholesale_cost BETWEEN 5.00 AND 20.00
      AND c.c_birth_day BETWEEN 1 AND 20
      AND cr.cr_catalog_page_sk > 100
      AND cr.cr_store_credit > 10.00

    UNION ALL

    SELECT
        i.i_item_id AS item_id,
        i.i_class_id AS class_id,
        i.i_manager_id AS manager_id,
        i.i_wholesale_cost AS wholesale_cost,
        c.c_customer_id AS customer_id,
        c.c_birth_day AS birth_day,
        sr.sr_net_loss AS net_loss,
        'store' AS return_type,
        r.r_reason_desc AS reason_desc
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE i.i_class_id IN (1, 3, 6)
      AND i.i_manager_id NOT IN (23)
      AND i.i_wholesale_cost BETWEEN 5.00 AND 20.00
      AND c.c_birth_day BETWEEN 1 AND 20
      AND sr.sr_return_quantity >= 2
      AND sr.sr_return_amt > 0
)
SELECT
    item_id,
    class_id,
    manager_id,
    wholesale_cost,
    customer_id,
    birth_day,
    net_loss,
    return_type,
    reason_desc,
    CASE 
        WHEN net_loss > 50 THEN 'High'
        WHEN net_loss > 20 THEN 'Medium'
        ELSE 'Low'
    END AS loss_severity,
    RANK() OVER (PARTITION BY class_id ORDER BY net_loss DESC) AS loss_rank
FROM combined_returns
WHERE net_loss IS NOT NULL
ORDER BY class_id, loss_rank
LIMIT 100
