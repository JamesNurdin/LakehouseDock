WITH cr_agg AS (
    SELECT
        cr_item_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        cr_reason_sk,
        cr_refunded_customer_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount)   AS total_return_amt,
        SUM(cr_net_loss)        AS total_net_loss,
        COUNT(*)                AS return_cnt
    FROM catalog_returns
    GROUP BY
        cr_item_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        cr_reason_sk,
        cr_refunded_customer_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk
)
SELECT
    cc.cc_state,
    sm.sm_carrier,
    i.i_brand,
    i.i_category,
    r.r_reason_desc,
    SUM(cr_agg.total_return_qty) AS sum_return_qty,
    SUM(cr_agg.total_return_amt) AS sum_return_amt,
    SUM(cr_agg.total_net_loss)   AS sum_net_loss,
    CASE
        WHEN SUM(cr_agg.total_net_loss) > 5000 THEN 'High'
        WHEN SUM(cr_agg.total_net_loss) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS net_loss_category
FROM cr_agg
JOIN item i               ON cr_agg.cr_item_sk        = i.i_item_sk
JOIN call_center cc       ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp      ON cr_agg.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm         ON cr_agg.cr_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN warehouse w          ON cr_agg.cr_warehouse_sk   = w.w_warehouse_sk
JOIN reason r             ON cr_agg.cr_reason_sk      = r.r_reason_sk
JOIN customer c           ON cr_agg.cr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cr_agg.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca  ON cr_agg.cr_refunded_addr_sk   = ca.ca_address_sk
WHERE
    i.i_rec_start_date >= DATE '2001-01-01'
    AND i.i_rec_start_date < DATE '2002-01-01'
    AND cc.cc_state IN ('WA', 'GA')
    AND sm.sm_carrier = 'DHL'
    AND EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_address_sk = cr_agg.cr_refunded_addr_sk
          AND ca2.ca_state = 'CA'
    )
GROUP BY
    cc.cc_state,
    sm.sm_carrier,
    i.i_brand,
    i.i_category,
    r.r_reason_desc
HAVING
    SUM(cr_agg.total_return_amt) > 10000
ORDER BY
    sum_net_loss DESC
LIMIT 100
