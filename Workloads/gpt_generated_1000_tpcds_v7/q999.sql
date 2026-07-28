WITH filtered_returns AS (
    SELECT
        i.i_manufact,
        i.i_product_name,
        sr.sr_net_loss,
        c.c_customer_sk,
        s.s_store_sk,
        inv.inv_quantity_on_hand,
        w.w_state
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(i.i_manufact, '^bar')
      AND s.s_street_type LIKE '%Street%'
      AND s.s_suite_number LIKE '%0'
      AND inv.inv_quantity_on_hand > 500
      AND w.w_state = 'CA'
)
SELECT
    i_manufact,
    CONCAT(i_product_name, ' - ', i_manufact) AS product_manufact,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    SUM(sr_net_loss) AS total_net_loss
FROM filtered_returns
GROUP BY i_manufact, i_product_name
ORDER BY total_net_loss DESC
LIMIT 20
