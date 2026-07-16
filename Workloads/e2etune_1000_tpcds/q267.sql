WITH returns AS (
    SELECT
        sr.sr_reason_sk AS reason_sk,
        i.i_category AS category,
        sr.sr_return_amt AS return_amount,
        sr.sr_return_tax AS return_tax,
        sr.sr_return_amt_inc_tax AS return_amt_inc_tax,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS quantity,
        i.i_item_sk AS item_sk
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2458840 AND 2459215
      AND i.i_category = 'Electronics'
      AND c.c_birth_year > 1970

    UNION ALL

    SELECT
        cr.cr_reason_sk AS reason_sk,
        i.i_category AS category,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_tax AS return_tax,
        cr.cr_return_amt_inc_tax AS return_amt_inc_tax,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS quantity,
        i.i_item_sk AS item_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2458840 AND 2459215
      AND i.i_category = 'Electronics'
      AND c.c_birth_year > 1970

    UNION ALL

    SELECT
        wr.wr_reason_sk AS reason_sk,
        i.i_category AS category,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_tax AS return_tax,
        wr.wr_return_amt_inc_tax AS return_amt_inc_tax,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS quantity,
        i.i_item_sk AS item_sk
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2458840 AND 2459215
      AND i.i_category = 'Electronics'
      AND c.c_birth_year > 1970
),
agg AS (
    SELECT
        r.r_reason_desc AS reason,
        t.category AS item_category,
        SUM(t.return_amount) AS total_return_amount,
        SUM(t.return_tax) AS total_return_tax,
        SUM(t.return_amt_inc_tax) AS total_return_inc_tax,
        SUM(t.net_loss) AS total_net_loss,
        SUM(t.quantity) AS total_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM returns t
    JOIN reason r ON t.reason_sk = r.r_reason_sk
    JOIN inventory inv ON t.item_sk = inv.inv_item_sk
    GROUP BY r.r_reason_desc, t.category
    HAVING SUM(t.net_loss) > 0
)
SELECT
    reason,
    item_category,
    total_return_amount,
    total_return_tax,
    total_return_inc_tax,
    total_net_loss,
    total_quantity,
    avg_inventory_on_hand,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 10
