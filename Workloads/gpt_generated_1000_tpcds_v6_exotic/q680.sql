WITH base AS (
    SELECT
        i.i_item_id,
        d.d_year,
        SUM(cs.cs_net_paid) AS catalog_sales_net,
        SUM(ss.ss_net_paid) AS store_sales_net,
        SUM(ws.ws_net_paid) AS web_sales_net,
        SUM(cs.cs_quantity + ss.ss_quantity + ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT s.s_store_id) AS distinct_stores,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN cs.cs_ext_discount_amt ELSE 0 END) AS promo_discount_sum,
        COUNT(DISTINCT p.p_promo_id) AS distinct_promos
    FROM
        tpcds.date_dim d
        JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
        JOIN tpcds.catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
        JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
                                 AND inv.inv_date_sk = d.d_date_sk
        JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
        JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                                 AND ss.ss_item_sk = i.i_item_sk
                                 AND ss.ss_store_sk = s.s_store_sk
        JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN tpcds.store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
        JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
        JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                                 AND ws.ws_item_sk = i.i_item_sk
                                 AND ws.ws_web_page_sk = wp.wp_web_page_sk
                                 AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                                 AND ws.ws_warehouse_sk = w.w_warehouse_sk
                                 AND ws.ws_promo_sk = p.p_promo_sk
    WHERE
        d.d_year = 2001
        AND i.i_current_price > 20
        AND s.s_state = 'CA'
        AND sm.sm_carrier IN ('UPS', 'USPS')
        AND p.p_discount_active = 'Y'
        AND ca.ca_country = 'United States'
    GROUP BY
        i.i_item_id,
        d.d_year
)
SELECT
    i_item_id,
    d_year,
    (catalog_sales_net + store_sales_net + web_sales_net) AS total_sales,
    total_quantity,
    distinct_stores,
    promo_discount_sum,
    distinct_promos,
    CASE WHEN (catalog_sales_net + store_sales_net + web_sales_net) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
    ROW_NUMBER() OVER (ORDER BY (catalog_sales_net + store_sales_net + web_sales_net) DESC) AS sales_rank
FROM
    base
WHERE
    (catalog_sales_net + store_sales_net + web_sales_net) > 50000
ORDER BY
    total_sales DESC
LIMIT 100
