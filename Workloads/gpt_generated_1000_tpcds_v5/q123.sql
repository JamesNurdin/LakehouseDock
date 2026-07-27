WITH high_inventory AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           inv.inv_quantity_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 800
)
SELECT combined.i_item_sk,
       combined.i_product_name,
       combined.metric_type,
       combined.total_quantity,
       combined.total_amount
FROM (
    SELECT hi.i_item_sk,
           hi.i_product_name,
           'sales'   AS metric_type,
           SUM(ss.ss_quantity)      AS total_quantity,
           SUM(ss.ss_net_paid)      AS total_amount
    FROM high_inventory hi
    JOIN store_sales ss ON ss.ss_item_sk = hi.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY hi.i_item_sk, hi.i_product_name
    HAVING SUM(ss.ss_net_paid) > 1000
    UNION ALL
    SELECT hi.i_item_sk,
           hi.i_product_name,
           'returns' AS metric_type,
           SUM(sr.sr_return_quantity) AS total_quantity,
           SUM(sr.sr_return_amt)      AS total_amount
    FROM high_inventory hi
    JOIN store_returns sr ON sr.sr_item_sk = hi.i_item_sk
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    WHERE sr.sr_return_quantity > 0
    GROUP BY hi.i_item_sk, hi.i_product_name
    HAVING SUM(sr.sr_return_amt) > 500
) AS combined
ORDER BY combined.total_amount DESC
