WITH
    base AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_item_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_addr_sk,
            cs.cs_ship_customer_sk,
            cs.cs_ship_addr_sk,
            cs.cs_ship_mode_sk,
            cs.cs_warehouse_sk,
            cs.cs_order_number,
            cs.cs_ext_sales_price,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            ss.ss_ext_sales_price AS ss_ext_sales_price,
            ws.ws_ext_sales_price AS ws_ext_sales_price,
            i.i_item_id,
            i.i_category,
            i.i_brand,
            p.p_promo_id,
            p.p_discount_active,
            sm.sm_ship_mode_id,
            sm.sm_code,
            w.w_warehouse_id,
            w.w_county,
            w.w_warehouse_sk,
            ca.ca_state,
            d.d_year,
            t.t_hour,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            wp.wp_web_page_id,
            ws.ws_web_site_sk,
            ws_site.web_name,
            inv.inv_quantity_on_hand
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
            AND ss.ss_item_sk = i.i_item_sk
            AND ss.ss_customer_sk = c.c_customer_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_item_sk = i.i_item_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
    ),
    warehouse_union AS (
        SELECT DISTINCT w_warehouse_sk FROM warehouse
        UNION
        SELECT DISTINCT ws_warehouse_sk FROM web_sales
    )
SELECT
    b.d_year,
    b.i_category,
    b.i_brand,
    b.sm_ship_mode_id,
    b.w_warehouse_id,
    b.w_county,
    b.ca_state,
    b.web_name,
    SUM(b.cs_ext_sales_price) AS total_catalog_sales,
    SUM(COALESCE(b.ss_ext_sales_price, 0)) AS total_store_sales,
    SUM(COALESCE(b.ws_ext_sales_price, 0)) AS total_web_sales,
    SUM(COALESCE(b.inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY b.i_category ORDER BY SUM(b.cs_ext_sales_price) DESC) AS sales_rank_by_category
FROM base b
WHERE b.d_year = 2001
  AND b.w_county IN ('Daviess County', 'Richland County')
  AND b.sm_code = 'AIR'
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_id = b.p_promo_id
          AND p2.p_discount_active = 'Y'
    )
  AND b.w_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse_union)
GROUP BY
    b.d_year,
    b.i_category,
    b.i_brand,
    b.sm_ship_mode_id,
    b.w_warehouse_id,
    b.w_county,
    b.ca_state,
    b.web_name
ORDER BY total_catalog_sales DESC
LIMIT 100
