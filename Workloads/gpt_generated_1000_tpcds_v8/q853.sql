WITH
sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
unsold_items AS (
    SELECT inv_item_sk
    FROM sampled_inventory
    EXCEPT
    SELECT ss_item_sk
    FROM store_sales
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    ca.ca_state,
    p.p_promo_name,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    sr.sr_return_quantity,
    wr.wr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ss.ss_ext_sales_price DESC) AS rn_item_sales,
    COUNT(DISTINCT ca.ca_state) OVER () AS distinct_states_total,
    COUNT(DISTINCT p.p_promo_id) OVER () AS distinct_promos_total,
    CASE WHEN ui.inv_item_sk IS NOT NULL THEN 1 ELSE 0 END AS is_unsold_item_flag
FROM sampled_inventory si
JOIN item i ON si.inv_item_sk = i.i_item_sk
JOIN warehouse w ON si.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN unsold_items ui ON ui.inv_item_sk = i.i_item_sk
WHERE
    i.i_current_price > 20
    AND p.p_discount_active = 'Y'
    AND ca.ca_state IN ('CA', 'TX')
    AND w.w_warehouse_sq_ft > 10000
    AND ss.ss_quantity > 5
    AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_return_quantity > 0
    )
ORDER BY rn_item_sales ASC
LIMIT 100
