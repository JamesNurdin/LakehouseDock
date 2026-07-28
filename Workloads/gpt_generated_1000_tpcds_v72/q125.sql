WITH sales_joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        t.t_hour,
        i.i_item_id,
        i.i_category,
        i.i_wholesale_cost AS i_wholesale_cost,
        i.i_manager_id,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        inv.inv_quantity_on_hand,
        wp.wp_url
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN web_page wp
        ON c.c_customer_sk = wp.wp_customer_sk
    WHERE
        i.i_wholesale_cost > 20.00
        AND i.i_manager_id IN (26, 40)
        AND inv.inv_quantity_on_hand > 100
        AND t.t_hour BETWEEN 9 AND 17
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = ss.ss_item_sk
              AND cr.cr_returned_time_sk = ss.ss_sold_time_sk
              AND cr.cr_warehouse_sk IN (6, 13)
        )
)
SELECT
    c_customer_id,
    i_category,
    t_hour,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_profit) AS avg_profit,
    COUNT(*) AS transaction_cnt,
    COUNT(DISTINCT ca_state) AS distinct_states,
    MIN(inv_quantity_on_hand) AS min_qty_on_hand,
    MAX(i_wholesale_cost) AS max_wholesale_cost
FROM sales_joined
GROUP BY c_customer_id, i_category, t_hour
HAVING SUM(ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
