WITH base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        i1.i_item_id,
        cc.cc_name,
        sm.sm_type,
        r.r_reason_desc,
        cd_refunded.cd_gender AS refunded_gender,
        cd_returning.cd_gender AS returning_gender,
        p.p_promo_name,
        inv.inv_quantity_on_hand
    FROM catalog_returns cr
    JOIN item i1 ON cr.cr_item_sk = i1.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i1.i_item_sk
    JOIN promotion p ON p.p_item_sk = i1.i_item_sk
),
wr_base AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        i2.i_item_id AS wr_item_id,
        r2.r_reason_desc AS wr_reason_desc,
        cd2.cd_gender AS wr_refunded_gender
    FROM web_returns wr
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN customer_demographics cd2 ON wr.wr_refunded_cdemo_sk = cd2.cd_demo_sk
)
SELECT
    COALESCE(b.cr_order_number, w.wr_order_number) AS order_number,
    SUM(COALESCE(b.cr_return_amount, 0) + COALESCE(w.wr_return_amt, 0)) AS total_return_amount,
    COUNT(DISTINCT COALESCE(b.cr_order_number, w.wr_order_number)) AS distinct_orders,
    MIN(COALESCE(b.cr_return_quantity, w.wr_return_quantity)) AS min_quantity,
    MAX(COALESCE(b.inv_quantity_on_hand, 0)) AS max_inventory_on_hand,
    MAX(COALESCE(b.p_promo_name, '')) AS promo_name,
    MAX(COALESCE(b.r_reason_desc, w.wr_reason_desc)) AS reason_desc
FROM base b
FULL OUTER JOIN wr_base w
    ON b.cr_order_number = w.wr_order_number
WHERE COALESCE(b.cr_order_number, w.wr_order_number) NOT IN (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount > 10000
)
GROUP BY COALESCE(b.cr_order_number, w.wr_order_number)
ORDER BY total_return_amount DESC
LIMIT 100
