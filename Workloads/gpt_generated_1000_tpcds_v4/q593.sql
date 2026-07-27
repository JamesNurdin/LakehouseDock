WITH
store_sales_cte AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        i.i_category,
        i.i_brand,
        c.c_first_name AS customer_first_name,
        c.c_last_name AS customer_last_name,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_amount,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_net_paid DESC) AS rank_num,
        'Store' AS source,
        s.s_store_name AS location_name,
        CASE WHEN ss.ss_quantity > 10 THEN 'Bulk' ELSE 'Regular' END AS purchase_type
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = ss.ss_item_sk
                         AND inv.inv_date_sk = ss.ss_sold_date_sk
    WHERE d_sales.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_color = 'RED'
),
catalog_sales_cte AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        i.i_category,
        i.i_brand,
        c.c_first_name AS customer_first_name,
        c.c_last_name AS customer_last_name,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_amount,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_warehouse_sk ORDER BY cs.cs_net_paid DESC) AS rank_num,
        'Catalog' AS source,
        w.w_warehouse_name AS location_name,
        CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS purchase_type
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = cs.cs_item_sk
                         AND inv.inv_date_sk = cs.cs_sold_date_sk
    WHERE d_sales.d_month_seq BETWEEN 1200 AND 1212
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
),
returns_cte AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        i.i_category,
        i.i_brand,
        rc.c_first_name AS customer_first_name,
        rc.c_last_name AS customer_last_name,
        cr.cr_return_quantity AS quantity,
        -cr.cr_refunded_cash AS net_amount,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_warehouse_sk ORDER BY cr.cr_refunded_cash DESC) AS rank_num,
        'CatalogReturn' AS source,
        w.w_warehouse_name AS location_name,
        CASE WHEN cr.cr_return_quantity > 3 THEN 'High' ELSE 'Low' END AS purchase_type
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer rc ON cr.cr_refunded_customer_sk = rc.c_customer_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = cr.cr_item_sk
                         AND inv.inv_date_sk = cr.cr_returned_date_sk
    WHERE d_ret.d_year = 2001
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
    UNION ALL
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk,
        i.i_category,
        i.i_brand,
        rc.c_first_name AS customer_first_name,
        rc.c_last_name AS customer_last_name,
        wr.wr_return_quantity AS quantity,
        -wr.wr_refunded_cash AS net_amount,
        ROW_NUMBER() OVER (PARTITION BY wp.wp_web_page_id ORDER BY wr.wr_refunded_cash DESC) AS rank_num,
        'WebReturn' AS source,
        wp.wp_url AS location_name,
        CASE WHEN wr.wr_return_quantity > 3 THEN 'High' ELSE 'Low' END AS purchase_type
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer rc ON wr.wr_refunded_customer_sk = rc.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_wp.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = wr.wr_item_sk
                         AND inv.inv_date_sk = wr.wr_returned_date_sk
    WHERE d_ret.d_year = 2001
      AND ws.web_country = 'USA'
      AND wp.wp_image_count > 2
)
SELECT
    date_sk,
    item_sk,
    i_category,
    i_brand,
    customer_first_name,
    customer_last_name,
    quantity,
    net_amount,
    source,
    location_name,
    purchase_type,
    rank_num
FROM (
    SELECT * FROM store_sales_cte
    UNION ALL
    SELECT * FROM catalog_sales_cte
    UNION ALL
    SELECT * FROM returns_cte
) combined
ORDER BY net_amount DESC
LIMIT 100
