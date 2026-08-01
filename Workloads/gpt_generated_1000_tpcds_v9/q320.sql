WITH high_value_items AS (
    SELECT i_item_sk FROM item WHERE i_current_price > 500
    UNION
    SELECT i_item_sk FROM item WHERE i_brand = 'BrandA'
)
SELECT
    c.c_customer_id,
    i.i_item_id,
    i.i_product_name,
    ss.ss_sold_date_sk,
    td.t_time,
    ss.ss_quantity,
    ss.ss_net_paid,
    (ss.ss_net_paid - COALESCE(sr.sr_refunded_cash, 0)) AS net_sales,
    (SELECT COUNT(*) FROM store_returns r3 WHERE r3.sr_item_sk = i.i_item_sk) AS total_returns_for_item,
    CASE WHEN sr.sr_ticket_number IS NOT NULL THEN 'Returned' ELSE 'Sold' END AS sale_status,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss.ss_net_paid DESC) AS category_rank,
    SUM(ss.ss_net_paid) OVER (PARTITION BY i.i_item_id ORDER BY td.t_time ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_sales
FROM store_sales ss
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
WHERE
    inv.inv_date_sk >= 2450900
    AND inv.inv_warehouse_sk = 15
    AND td.t_meal_time = 'lunch'
    AND i.i_current_price > 20
    AND c.c_salutation = 'Mrs.'
    AND EXISTS (SELECT 1 FROM high_value_items hvi WHERE hvi.i_item_sk = i.i_item_sk)
    AND NOT EXISTS (
        SELECT 1
        FROM store_returns r_ex
        WHERE r_ex.sr_customer_sk = c.c_customer_sk
          AND r_ex.sr_net_loss > 0
    )
ORDER BY category_rank ASC, rolling_3_sales DESC
LIMIT 100
