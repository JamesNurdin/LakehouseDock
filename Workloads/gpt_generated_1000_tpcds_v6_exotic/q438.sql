WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_amt_inc_tax,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_item_sk,
        i.i_item_id,
        i.i_color,
        i.i_current_price,
        cc.cc_name,
        cc.cc_state,
        inv.inv_quantity_on_hand,
        p.p_promo_name,
        p.p_discount_active
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_color IN ('yellow', 'papaya')
      AND i.i_current_price BETWEEN 10 AND 100
      AND inv.inv_quantity_on_hand > 500
      AND p.p_discount_active = 'Y'
      AND cr.cr_returned_date_sk BETWEEN 2450800 AND 2451100
),
aggregated AS (
    SELECT
        i_item_id,
        i_color,
        cc_name,
        p_promo_name,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(*) AS return_cnt,
        MAX(cr_return_amt_inc_tax) AS max_return_inc_tax,
        MIN(inv_quantity_on_hand) AS min_qty_on_hand
    FROM filtered
    GROUP BY i_item_id, i_color, cc_name, p_promo_name
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    i_item_id,
    i_color,
    cc_name,
    p_promo_name,
    total_return_amount,
    avg_return_amount,
    return_cnt,
    max_return_inc_tax,
    min_qty_on_hand,
    ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY total_return_amount DESC) AS rn
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
