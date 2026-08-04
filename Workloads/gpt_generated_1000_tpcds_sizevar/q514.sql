WITH intersect_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_quantity > 5
        INTERSECT
        SELECT cr_order_number
        FROM catalog_returns
        WHERE cr_return_quantity > 0
    )
SELECT
        w.w_warehouse_name,
        i.i_category,
        sm.sm_type,
        SUM(cs.cs_net_paid)                         AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number)          AS distinct_orders,
        AVG(cr.cr_return_amount)                    AS avg_return_amount,
        MIN(p.p_cost)                               AS min_promo_cost,
        MAX(w.w_gmt_offset)                         AS max_gmt_offset,
        CASE WHEN cr.cr_return_quantity > 0 THEN 'Returned' ELSE 'No Return' END AS return_flag,
        (
            SELECT SUM(cs2.cs_quantity)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = i.i_item_sk
        )                                            AS total_quantity_for_item,
        COUNT(DISTINCT word)                        AS distinct_promo_words
FROM catalog_sales cs
JOIN intersect_orders io
     ON cs.cs_order_number = io.cs_order_number
JOIN time_dim td
     ON cs.cs_sold_time_sk = td.t_time_sk
JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN LATERAL (
        SELECT word
        FROM UNNEST(split(p.p_channel_details, ' ')) AS t(word)
    ) pu ON true
JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
JOIN web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_time_sk = td.t_time_sk
WHERE td.t_hour = 14
  AND w.w_city = 'Seattle'
  AND p.p_channel_dmail = 'Y'
GROUP BY
    w.w_warehouse_name,
    i.i_category,
    sm.sm_type,
    i.i_item_sk,
    CASE WHEN cr.cr_return_quantity > 0 THEN 'Returned' ELSE 'No Return' END
ORDER BY total_net_paid DESC
OFFSET 10
LIMIT 100
