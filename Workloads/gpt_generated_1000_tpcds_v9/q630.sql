WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand,
           COUNT(DISTINCT inv_warehouse_sk) AS warehouse_count
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_class_id,
    i.i_current_price,
    p.p_promo_name,
    cc.cc_name,
    cd_ref.cd_gender,
    inv.total_qty_on_hand,
    ret.total_return_amount,
    CASE
        WHEN ret.total_return_amount >= 5000 THEN 'Very High'
        WHEN ret.total_return_amount >= 1000 THEN 'High'
        WHEN ret.total_return_amount >= 200 THEN 'Medium'
        ELSE 'Low'
    END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ret.total_return_amount DESC) AS rank_in_category
FROM
    catalog_returns cr
FULL OUTER JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
LEFT JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
LEFT JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
LEFT JOIN inv_agg inv
    ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN LATERAL (
    SELECT
        COUNT(*) AS return_cnt,
        SUM(cr2.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = i.i_item_sk
) ret ON TRUE
WHERE
    i.i_class_id IN (1, 10, 11)
    AND i.i_rec_start_date >= DATE '1999-01-01'
    AND p.p_channel_tv = 'Y'
    AND cc.cc_state = 'CA'
    AND cd_ref.cd_gender = 'M'
    AND cr.cr_return_amount > 50
    AND inv.total_qty_on_hand > 10
    AND p.p_cost < (SELECT MAX(p_cost) FROM promotion WHERE p_channel_tv = 'Y')
ORDER BY
    i.i_category,
    rank_in_category
