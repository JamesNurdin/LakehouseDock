WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk, inv_warehouse_sk
),
cust_web AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_returned_date_sk AS date_sk,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    WHERE wr.wr_reason_sk IN (13, 56)
    GROUP BY wr.wr_refunded_customer_sk, wr.wr_returned_date_sk
)
SELECT
    c.c_customer_id,
    d.d_date,
    cp.cp_type,
    w.w_warehouse_name,
    inv_agg.total_qty_on_hand,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    cw.web_net_loss,
    CASE
        WHEN SUM(cr.cr_return_amount) > 200 THEN 'High'
        ELSE 'Low'
    END AS return_amount_category,
    (SELECT AVG(cr2.cr_net_loss)
     FROM catalog_returns cr2
     WHERE cr2.cr_returned_date_sk = d.d_date_sk) AS avg_catalog_net_loss_on_date
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_date_sk = d.d_date_sk
    AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN cust_web cw
    ON cw.customer_sk = c.c_customer_sk
    AND cw.date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND cp.cp_type = 'monthly'
    AND c.c_preferred_cust_flag = 'Y'
    AND w.w_country = 'United States'
GROUP BY
    c.c_customer_id,
    d.d_date,
    cp.cp_type,
    w.w_warehouse_name,
    inv_agg.total_qty_on_hand,
    cw.web_net_loss,
    (SELECT AVG(cr2.cr_net_loss)
     FROM catalog_returns cr2
     WHERE cr2.cr_returned_date_sk = d.d_date_sk)
HAVING
    SUM(cr.cr_net_loss) > 1000
ORDER BY total_catalog_net_loss DESC
LIMIT 100
