WITH agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        ca_store.ca_state AS store_state,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_combined_sales,
        CASE WHEN i.i_current_price > 100 THEN 'HIGH' ELSE 'LOW' END AS price_category,
        i.i_current_price
    FROM
        store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        JOIN customer_address ca_web ON ws.ws_bill_addr_sk = ca_web.ca_address_sk
    WHERE
        ca_store.ca_state = 'TX'
        AND i.i_class_id IN (1, 3, 7)
        AND ss.ss_list_price > 50
        AND ws.ws_net_paid_inc_ship > 1000
        AND i.i_formulation LIKE '%blue%'
        AND EXISTS (
            SELECT 1
            FROM warehouse w
            WHERE w.w_warehouse_sk = ws.ws_warehouse_sk
              AND w.w_state = 'CA'
        )
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        ca_store.ca_state,
        i.i_current_price
)
SELECT
    i_item_id,
    i_product_name,
    store_state,
    store_sales_amount,
    web_sales_amount,
    total_combined_sales,
    price_category,
    ROW_NUMBER() OVER (ORDER BY total_combined_sales DESC) AS sales_rank
FROM agg
ORDER BY sales_rank
LIMIT 100
