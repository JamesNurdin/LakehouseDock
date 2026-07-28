/* Goal: Summarize catalog return performance by warehouse, item category and return reason, while restricting to recent returns with significant amounts, filtering on warehouse location, ensuring sufficient inventory on hand, and excluding items that have any low‑stock records. */
WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        i.i_category,
        r.r_reason_desc,
        w.w_warehouse_name,
        w.w_city
    FROM catalog_returns cr
    JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
        AND wr.wr_returning_customer_sk = c_returning.c_customer_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE
        cr.cr_returned_date_sk BETWEEN 2450800 AND 2450900               -- recent return dates
        AND cr.cr_return_quantity > 1                                    -- more than one unit returned
        AND cr.cr_return_amount > 50.00                                 -- return amount exceeds $50
        AND w.w_city = 'Center'                                          -- warehouse located in Center city
        AND EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = i.i_item_sk
              AND inv.inv_warehouse_sk = w.w_warehouse_sk
              AND inv.inv_quantity_on_hand >= 200                     -- sufficient stock on hand
        )
        AND NOT EXISTS (
            SELECT 1
            FROM inventory inv_low
            WHERE inv_low.inv_item_sk = i.i_item_sk
              AND inv_low.inv_quantity_on_hand < 50                     -- exclude any low‑stock situation
        )
)
SELECT
    w_warehouse_name,
    i_category,
    r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_qty,
    MAX(cr_net_loss) AS max_net_loss,
    MIN(cr_return_tax) AS min_return_tax
FROM filtered_returns
GROUP BY w_warehouse_name, i_category, r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
