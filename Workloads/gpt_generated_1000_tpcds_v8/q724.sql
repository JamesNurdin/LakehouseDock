WITH
    sampled_inventory AS (
        SELECT inv_item_sk,
               inv_quantity_on_hand,
               inv_date_sk
        FROM inventory TABLESAMPLE BERNOULLI (5)
    ),
    filtered_customers AS (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE c.c_customer_sk IN (SELECT cr_refunded_customer_sk FROM catalog_returns)
    ),
    base AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_item_sk,
            cs.cs_order_number,
            cs.cs_net_paid,
            cp.cp_department,
            p.p_promo_name,
            sm.sm_type,
            d.d_year,
            t.t_hour,
            cust_bill.c_customer_sk AS bill_cust_sk,
            cust_ship.c_customer_sk AS ship_cust_sk,
            ca_bill.ca_state AS bill_state,
            ca_ship.ca_state AS ship_state,
            hd_bill.hd_income_band_sk AS bill_income_band,
            hd_ship.hd_income_band_sk AS ship_income_band,
            si.inv_quantity_on_hand
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
        JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN filtered_customers fc ON cs.cs_bill_customer_sk = fc.c_customer_sk
        LEFT JOIN sampled_inventory si ON si.inv_item_sk = cs.cs_item_sk
            AND si.inv_date_sk = cs.cs_sold_date_sk
    ),
    returns AS (
        SELECT
            cr.cr_order_number,
            cr.cr_item_sk,
            r.r_reason_desc,
            cr.cr_return_amount
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_return_amount > 0
    ),
    store_part AS (
        SELECT
            ss.ss_store_sk,
            ss.ss_sold_date_sk,
            ss.ss_net_paid,
            s.s_store_name,
            d2.d_year
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    ),
    web_part AS (
        SELECT
            ws.ws_web_site_sk,
            ws.ws_sold_date_sk,
            ws.ws_net_paid,
            ws_site.web_name,
            d3.d_year
        FROM web_sales ws
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN date_dim d3 ON ws.ws_sold_date_sk = d3.d_date_sk
    ),
    combined AS (
        SELECT
            'catalog' AS src,
            b.cp_department AS category,
            b.p_promo_name AS promo,
            b.d_year,
            SUM(b.cs_net_paid) AS total_net,
            COUNT(DISTINCT b.cs_order_number) AS orders,
            r.r_reason_desc AS reason
        FROM base b
        JOIN returns r ON b.cs_order_number = r.cr_order_number
            AND b.cs_item_sk = r.cr_item_sk
        GROUP BY b.cp_department, b.p_promo_name, b.d_year, r.r_reason_desc
        UNION ALL
        SELECT
            'store' AS src,
            sp.s_store_name AS category,
            NULL AS promo,
            sp.d_year,
            SUM(sp.ss_net_paid) AS total_net,
            COUNT(DISTINCT sp.ss_store_sk) AS orders,
            NULL AS reason
        FROM store_part sp
        GROUP BY sp.s_store_name, sp.d_year
        UNION ALL
        SELECT
            'web' AS src,
            wp.web_name AS category,
            NULL AS promo,
            wp.d_year,
            SUM(wp.ws_net_paid) AS total_net,
            COUNT(DISTINCT wp.ws_web_site_sk) AS orders,
            NULL AS reason
        FROM web_part wp
        GROUP BY wp.web_name, wp.d_year
    ),
    intersected AS (
        SELECT src, category FROM combined
        INTERSECT
        SELECT 'catalog' AS src, cp_department FROM catalog_page WHERE cp_department = 'Books'
    )
SELECT
    src,
    category,
    promo,
    d_year,
    total_net,
    orders,
    reason
FROM combined
WHERE (src, category) IN (SELECT src, category FROM intersected)
GROUP BY GROUPING SETS (
    (src, category, promo, d_year, total_net, orders, reason),
    (src, category, d_year, total_net),
    (src, category),
    (src)
)
ORDER BY total_net DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
