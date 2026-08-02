WITH
    inventory_summary AS (
        SELECT inv_warehouse_sk,
               SUM(inv_quantity_on_hand) AS total_inventory_quantity,
               COUNT(DISTINCT inv_item_sk) AS distinct_item_count
        FROM inventory
        GROUP BY inv_warehouse_sk
    ),
    sales_agg AS (
        SELECT
            store.s_store_id,
            store.s_store_name,
            store.s_state AS store_state,
            call_center.cc_name AS call_center_name,
            call_center.cc_state AS call_center_state,
            catalog_page.cp_type AS catalog_type,
            warehouse.w_warehouse_id,
            warehouse.w_state AS warehouse_state,
            warehouse.w_city AS warehouse_city,
            SUM(store_sales.ss_ext_sales_price) AS total_sales,
            AVG(store_sales.ss_net_paid) AS avg_net_paid,
            COUNT(DISTINCT store_sales.ss_ticket_number) AS order_count,
            MIN(store_sales.ss_ext_discount_amt) AS min_discount,
            MAX(store_sales.ss_ext_tax) AS max_tax,
            COALESCE(inventory_summary.total_inventory_quantity, 0) AS total_inventory_quantity,
            inventory_summary.distinct_item_count
        FROM store_sales
        INNER JOIN customer
            ON store_sales.ss_customer_sk = customer.c_customer_sk
        INNER JOIN store
            ON store_sales.ss_store_sk = store.s_store_sk
        INNER JOIN customer_address
            ON store_sales.ss_addr_sk = customer_address.ca_address_sk
        INNER JOIN web_page
            ON web_page.wp_customer_sk = customer.c_customer_sk
        INNER JOIN catalog_returns
            ON catalog_returns.cr_returning_customer_sk = customer.c_customer_sk
        INNER JOIN call_center
            ON catalog_returns.cr_call_center_sk = call_center.cc_call_center_sk
        INNER JOIN catalog_page
            ON catalog_returns.cr_catalog_page_sk = catalog_page.cp_catalog_page_sk
        INNER JOIN warehouse
            ON catalog_returns.cr_warehouse_sk = warehouse.w_warehouse_sk
        LEFT JOIN inventory_summary
            ON inventory_summary.inv_warehouse_sk = warehouse.w_warehouse_sk
        WHERE
            store.s_state = 'CA'
            AND store_sales.ss_quantity > 10
            AND store_sales.ss_net_paid > 1000
            AND call_center.cc_state = 'TX'
            AND catalog_page.cp_type = 'Electronics'
            AND warehouse.w_city = 'New York'
            AND web_page.wp_image_count >= 3
            AND store_sales.ss_ext_sales_price > (
                SELECT AVG(ss_ext_sales_price)
                FROM store_sales
                WHERE ss_quantity > 0
            )
        GROUP BY
            store.s_store_id,
            store.s_store_name,
            store.s_state,
            call_center.cc_name,
            call_center.cc_state,
            catalog_page.cp_type,
            warehouse.w_warehouse_id,
            warehouse.w_state,
            warehouse.w_city,
            inventory_summary.total_inventory_quantity,
            inventory_summary.distinct_item_count
    )
SELECT
    s_store_id,
    s_store_name,
    store_state,
    call_center_name,
    call_center_state,
    catalog_type,
    w_warehouse_id,
    warehouse_state,
    warehouse_city,
    total_sales,
    avg_net_paid,
    order_count,
    min_discount,
    max_tax,
    total_inventory_quantity,
    distinct_item_count,
    ROW_NUMBER() OVER (PARTITION BY store_state ORDER BY total_sales DESC) AS sales_rank,
    (SELECT SUM(inv_quantity_on_hand) FROM inventory) AS overall_inventory_quantity
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
