WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_category,
    i.i_current_price,
    (SELECT AVG(i2.i_current_price)
     FROM item i2
     WHERE i2.i_category_id = i.i_category_id) AS avg_cat_price,
    CASE
        WHEN i.i_current_price > (SELECT AVG(i2.i_current_price)
                                 FROM item i2
                                 WHERE i2.i_category_id = i.i_category_id) THEN 'above_avg'
        ELSE 'below_avg'
    END AS price_category,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    t.t_time,
    t.t_minute,
    ss.ss_quantity,
    ss.ss_net_paid,
    ia.total_qty_on_hand,
    ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY ss.ss_net_paid DESC) AS sales_rank
FROM store_sales ss
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN inventory_agg ia
    ON i.i_item_sk = ia.inv_item_sk
WHERE
    i.i_category_id = 6
    AND i.i_size = 'large'
    AND t.t_minute BETWEEN 5 AND 15
    AND c.c_salutation = 'Mr.'
    AND ss.ss_quantity > 1
ORDER BY i.i_category_id, sales_rank
LIMIT 100
