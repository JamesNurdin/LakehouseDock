WITH per_item AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_category AS category,
        cd.cd_gender AS gender,
        cr.cr_warehouse_sk AS warehouse_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        i.i_brand = 'BrandX' AND
        cd.cd_gender = 'F' AND
        s.s_state = 'CA' AND
        r.r_reason_desc = 'Did not like the color' AND
        cr.cr_return_amount > 100
    GROUP BY s.s_store_id, i.i_category, cd.cd_gender, cr.cr_warehouse_sk
)
SELECT
    store_id,
    category,
    gender,
    total_quantity_sold,
    total_net_paid,
    total_net_loss,
    avg_return_amount,
    total_return_amount,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS rn
FROM per_item
WHERE EXISTS (
    SELECT 1
    FROM warehouse w
    WHERE w.w_warehouse_sk = per_item.warehouse_sk
      AND w.w_state = 'CA'
)
  AND total_net_loss > (SELECT AVG(total_net_loss) FROM per_item) * 1.5
ORDER BY total_net_loss DESC
LIMIT 100
