/*
Goal: Rank items by total sales per year for 2000‑2002 while filtering on brand, warehouse state, promotion activity, web site class, and store state, joining all TPC‑DS tables to illustrate a comprehensive analytical view.
*/
WITH sales_agg AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        w.w_state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM tpcds.date_dim d
    JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_brand_id = 10
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND we.web_class = 'Unknown'
      AND s.s_state = 'TX'
    GROUP BY d.d_year, i.i_item_id, i.i_product_name, w.w_state
)
SELECT
    d_year,
    i_item_id,
    i_product_name,
    total_sales,
    orders,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    CASE
        WHEN w_state = 'CA' THEN 'West'
        WHEN w_state = 'TX' THEN 'South'
        ELSE 'Other'
    END AS region_flag
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
