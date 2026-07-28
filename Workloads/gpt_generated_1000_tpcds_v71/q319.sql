WITH all_returns AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_returned_time_sk AS time_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        cr.cr_reason_sk AS reason_sk,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount > 50
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = cr.cr_item_sk
            AND inv.inv_quantity_on_hand > 0
      )

    UNION ALL

    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_return_time_sk AS time_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        sr.sr_reason_sk AS reason_sk,
        'store' AS source
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_amt > 50
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = sr.sr_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
)
SELECT
    ar.source,
    ar.date_sk,
    ar.time_sk,
    i.i_item_id,
    i.i_category,
    r.r_reason_desc,
    c.c_customer_id,
    hd.hd_buy_potential,
    ar.return_amount,
    ar.net_loss,
    CASE WHEN ar.net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY ar.customer_sk ORDER BY ar.net_loss DESC) AS loss_rank
FROM all_returns ar
JOIN item i ON ar.item_sk = i.i_item_sk
JOIN reason r ON ar.reason_sk = r.r_reason_sk
JOIN customer c ON ar.customer_sk = c.c_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE i.i_category = 'Electronics'
ORDER BY loss_category DESC, ar.net_loss DESC
LIMIT 100
