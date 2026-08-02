WITH sub_a AS (
    SELECT
        d_cs.d_year AS year,
        p.p_promo_id AS promo_id,
        CASE
            WHEN cs.cs_net_profit > 1000 THEN 'High'
            WHEN cs.cs_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        COUNT(DISTINCT c_cs.c_customer_id) AS distinct_customers,
        SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) AS total_sales,
        inv_l.total_quantity_on_hand AS inventory_qty
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_close ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
    JOIN customer c_cs ON cs.cs_bill_customer_sk = c_cs.c_customer_sk
    JOIN household_demographics hd_cs ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN income_band ib_cs ON hd_cs.hd_income_band_sk = ib_cs.ib_income_band_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c_cs.c_customer_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN income_band ib_ss ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
    CROSS JOIN LATERAL (
        SELECT SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
        FROM inventory i
        WHERE i.inv_warehouse_sk = w.w_warehouse_sk
          AND i.inv_date_sk = d_cs.d_date_sk
    ) AS inv_l
    GROUP BY
        d_cs.d_year,
        p.p_promo_id,
        CASE
            WHEN cs.cs_net_profit > 1000 THEN 'High'
            WHEN cs.cs_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END,
        inv_l.total_quantity_on_hand
),
sub_b AS (
    SELECT
        d_ws.d_year AS year,
        p.p_promo_id AS promo_id,
        CASE
            WHEN ws.ws_net_profit > 1000 THEN 'High'
            WHEN ws.ws_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        COUNT(DISTINCT c_ws.c_customer_id) AS distinct_customers,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        inv_l.total_quantity_on_hand AS inventory_qty
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN income_band ib_ws ON hd_ws.hd_income_band_sk = ib_ws.ib_income_band_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN date_dim d_ws_site_open ON ws_site.web_open_date_sk = d_ws_site_open.d_date_sk
    JOIN date_dim d_ws_site_close ON ws_site.web_close_date_sk = d_ws_site_close.d_date_sk
    JOIN customer c_wp ON wp.wp_customer_sk = c_wp.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
        FROM inventory i
        WHERE i.inv_warehouse_sk = w_ws.w_warehouse_sk
          AND i.inv_date_sk = d_ws.d_date_sk
    ) AS inv_l
    GROUP BY
        d_ws.d_year,
        p.p_promo_id,
        CASE
            WHEN ws.ws_net_profit > 1000 THEN 'High'
            WHEN ws.ws_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END,
        inv_l.total_quantity_on_hand
),
unioned AS (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
)
SELECT
    year,
    promo_id,
    profit_category,
    distinct_orders,
    distinct_customers,
    total_sales,
    inventory_qty,
    ROW_NUMBER() OVER (PARTITION BY promo_id ORDER BY total_sales DESC) AS promo_sales_rank
FROM unioned
ORDER BY total_sales DESC, year DESC
LIMIT 100
