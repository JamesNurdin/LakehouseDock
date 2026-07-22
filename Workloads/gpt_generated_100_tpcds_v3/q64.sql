WITH joined_data AS (
    SELECT
        st.s_store_name AS s_store_name,
        d_sold.d_year AS sales_year,
        cs.cs_net_paid AS cs_net_paid,
        ss.ss_net_paid AS store_net_paid,
        cr.cr_return_amount AS cr_return_amount,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        cs.cs_order_number AS cs_order_number
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc_sales ON cs.cs_call_center_sk = cc_sales.cc_call_center_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN date_dim d_store_closed ON st.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
aggregated AS (
    SELECT
        s_store_name,
        sales_year,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(store_net_paid) AS total_store_sales,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(DISTINCT cs_order_number) AS num_orders
    FROM joined_data
    GROUP BY s_store_name, sales_year
)
SELECT
    s_store_name,
    sales_year,
    total_catalog_sales,
    total_store_sales,
    total_return_amount,
    total_inventory_on_hand,
    num_orders,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_catalog_sales DESC) AS sales_rank_in_year
FROM aggregated
ORDER BY sales_year, sales_rank_in_year
LIMIT 100
