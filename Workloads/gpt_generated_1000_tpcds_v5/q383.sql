WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        i.i_category,
        i.i_brand,
        t.t_hour,
        t.t_meal_time,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    WHERE i.i_class_id IN (4, 6, 9, 10, 16)
)
SELECT
    sd.cs_order_number,
    sd.i_category,
    sd.i_brand,
    SUM(sd.cs_quantity) AS total_qty_sold,
    SUM(sd.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT sd.cs_sold_time_sk) AS distinct_sale_times,
    CASE
        WHEN SUM(sd.cs_quantity) > 1000 THEN 'HIGH'
        WHEN SUM(sd.cs_quantity) > 500 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS volume_category,
    (
        SELECT COUNT(*)
        FROM store_returns sr_sub
        JOIN item i_sub ON sr_sub.sr_item_sk = i_sub.i_item_sk
        JOIN time_dim t_sub ON sr_sub.sr_return_time_sk = t_sub.t_time_sk
        WHERE i_sub.i_category = sd.i_category
          AND t_sub.t_hour BETWEEN 9 AND 17
    ) AS returns_during_day
FROM sales_data sd
JOIN store_returns sr2
    ON sr2.sr_item_sk = sd.cs_item_sk
JOIN time_dim t_return2
    ON sr2.sr_return_time_sk = t_return2.t_time_sk
JOIN item i_return2
    ON sr2.sr_item_sk = i_return2.i_item_sk
JOIN inventory inv2
    ON i_return2.i_item_sk = inv2.inv_item_sk
JOIN catalog_sales cs_extra
    ON cs_extra.cs_item_sk = sd.cs_item_sk
JOIN inventory inv_extra
    ON cs_extra.cs_item_sk = inv_extra.inv_item_sk
WHERE t_return2.t_meal_time = 'Dinner'
GROUP BY
    sd.cs_order_number,
    sd.i_category,
    sd.i_brand,
    sd.cs_sold_time_sk,
    sd.t_hour,
    sd.t_meal_time,
    sd.inv_quantity_on_hand
ORDER BY total_net_paid DESC
LIMIT 100
