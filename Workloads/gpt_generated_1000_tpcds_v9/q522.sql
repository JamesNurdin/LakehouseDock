WITH cat_ret AS (
    SELECT
        cr.cr_order_number AS order_number,
        cr.cr_return_amount AS return_amount,
        cr.cr_returned_date_sk AS return_date_sk,
        r.r_reason_desc AS reason_desc,
        cr.cr_item_sk AS item_sk,
        cr.cr_warehouse_sk AS warehouse_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > (
          SELECT max(cr2.cr_return_amount)
          FROM catalog_returns cr2
          WHERE cr2.cr_returned_date_sk = 20000101
      )
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = cr.cr_order_number
      )
),
web_ret AS (
    SELECT
        wr.wr_order_number AS order_number,
        wr.wr_return_amt AS return_amount,
        wr.wr_returned_date_sk AS return_date_sk,
        r.r_reason_desc AS reason_desc,
        wr.wr_item_sk AS item_sk,
        (
            SELECT w.w_warehouse_sk
            FROM warehouse w
            WHERE w.w_warehouse_id = 'W_001'
            LIMIT 1
        ) AS warehouse_sk
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND wr.wr_return_amt > (
          SELECT max(wr2.wr_return_amt)
          FROM web_returns wr2
          WHERE wr2.wr_returned_date_sk = 20000101
      )
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = wr.wr_order_number
      )
),
combined AS (
    SELECT order_number, return_amount, return_date_sk, reason_desc, item_sk, warehouse_sk
    FROM cat_ret
    UNION ALL
    SELECT order_number, return_amount, return_date_sk, reason_desc, item_sk, warehouse_sk
    FROM web_ret
),
order_exclusive AS (
    SELECT order_number FROM cat_ret
    EXCEPT
    SELECT order_number FROM web_ret
)
SELECT
    c.order_number,
    c.return_amount,
    d.d_date,
    c.reason_desc,
    (
        SELECT sum(i.inv_quantity_on_hand)
        FROM inventory i
        WHERE i.inv_item_sk = c.item_sk
          AND i.inv_warehouse_sk = c.warehouse_sk
          AND i.inv_date_sk = c.return_date_sk
    ) AS total_inventory_on_return_date
FROM combined c
JOIN date_dim d ON c.return_date_sk = d.d_date_sk
WHERE c.order_number IN (SELECT order_number FROM order_exclusive)
  AND c.return_amount > (
        SELECT avg(cr3.cr_return_amount)
        FROM catalog_returns cr3
        WHERE cr3.cr_returned_date_sk = 20000101
    )
ORDER BY c.return_amount DESC
LIMIT 100
