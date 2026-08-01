WITH
    filtered_items AS (
        SELECT i.i_item_sk,
               i.i_item_id,
               i.i_category,
               i.i_class,
               i.i_manufact,
               i.i_current_price
        FROM item i
        WHERE i.i_class_id IN (3, 4, 9, 12)
          AND i.i_current_price > 5
    ),
    cheap_items AS (
        SELECT i_item_sk
        FROM filtered_items
        WHERE i_current_price < 20
    ),
    high_class_items AS (
        SELECT i_item_sk
        FROM item
        WHERE i_class_id = 12
    ),
    union_item_keys AS (
        SELECT i_item_sk FROM cheap_items
        UNION
        SELECT i_item_sk FROM high_class_items
    ),
    promo_exclude AS (
        SELECT i_item_sk
        FROM item
        WHERE i_manufact LIKE 'bar%'
        EXCEPT
        SELECT p_item_sk
        FROM promotion
        WHERE p_channel_radio = 'Y'
    ),
    final_item_keys AS (
        SELECT i_item_sk FROM union_item_keys
        INTERSECT
        SELECT i_item_sk FROM promo_exclude
    ),
    agg_returns AS (
        SELECT i.i_item_sk,
               i.i_item_id,
               i.i_category,
               i.i_manufact,
               SUM(cr.cr_return_amount) AS total_return_amount,
               COUNT(*) AS return_cnt
        FROM catalog_returns cr
        JOIN filtered_items i
          ON cr.cr_item_sk = i.i_item_sk
        JOIN catalog_page cp
          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN time_dim td
          ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN call_center cc
          ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm
          ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN promotion p
          ON p.p_item_sk = i.i_item_sk
         AND p.p_channel_radio = 'N'
        LEFT JOIN inventory inv
          ON inv.inv_item_sk = i.i_item_sk
        JOIN customer c_refunded
          ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
        WHERE cc.cc_state = 'CA'
          AND cc.cc_gmt_offset BETWEEN -5 AND 0
          AND cp.cp_catalog_number IN (7, 13)
          AND td.t_hour BETWEEN 8 AND 17
          AND i.i_manufact LIKE 'bar%'
          AND i.i_item_sk IN (SELECT i_item_sk FROM final_item_keys)
          AND EXISTS (
              SELECT 1
              FROM promotion p2
              WHERE p2.p_item_sk = i.i_item_sk
                AND p2.p_discount_active = 'Y'
          )
        GROUP BY i.i_item_sk, i.i_item_id, i.i_category, i.i_manufact
    )
SELECT
    ar.i_item_id,
    ar.i_category,
    ar.i_manufact,
    ar.total_return_amount,
    RANK() OVER (PARTITION BY ar.i_category ORDER BY ar.total_return_amount DESC) AS category_rank,
    CASE WHEN ar.return_cnt > 10 THEN 'High' ELSE 'Low' END AS volume_flag,
    (SELECT avg(i3.i_current_price)
       FROM item i3
       WHERE i3.i_category = ar.i_category) AS avg_category_price,
    seq.seq_num
FROM agg_returns ar
CROSS JOIN (SELECT 1 AS seq_num UNION ALL SELECT 2 UNION ALL SELECT 3) seq
ORDER BY ar.total_return_amount DESC
LIMIT 100
