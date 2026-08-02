WITH
    -- Central fact: catalog_sales with all possible dimension joins
    catalog_sales_pre AS (
        SELECT
            cs.cs_order_number AS order_id,
            d.d_date AS order_date,
            c.c_first_name || ' ' || c.c_last_name AS customer_name,
            cd.cd_gender AS gender,
            cp.cp_department AS department,
            w.w_warehouse_name AS warehouse_name,
            cs.cs_quantity AS quantity,
            cs.cs_ext_sales_price AS sales_amount,
            cs.cs_net_paid AS net_paid,
            CASE
                WHEN cs.cs_quantity > 10 THEN 'Bulk'
                WHEN cs.cs_quantity BETWEEN 5 AND 10 THEN 'Medium'
                ELSE 'Small'
            END AS order_size,
            ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY d.d_date DESC) AS rn_customer_latest,
            p.p_promo_name,
            (SELECT COUNT(*) FROM tpcds.catalog_returns cr WHERE cr.cr_order_number = cs.cs_order_number) AS return_cnt,
            inv.quantity_on_hand AS inventory_on_hand
        FROM tpcds.catalog_sales cs
        JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN tpcds.time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
        -- LATERAL join to fetch the most recent inventory level for the warehouse/date
        CROSS JOIN LATERAL (
            SELECT i.inv_quantity_on_hand AS quantity_on_hand
            FROM tpcds.inventory i
            WHERE i.inv_warehouse_sk = w.w_warehouse_sk
              AND i.inv_date_sk = d.d_date_sk
            ORDER BY i.inv_date_sk DESC
            LIMIT 1
        ) AS inv
        WHERE d.d_year = 2001
          AND w.w_city = 'Seattle'
          AND cc.cc_state = 'CA'
          AND p.p_discount_active = 'Y'
          AND cd.cd_education_status = 'Advanced Degree'
          AND cs.cs_ext_sales_price > 1000
    ),
    -- Store sales (another channel) – star join through shared dimensions
    store_sales_pre AS (
        SELECT
            ss.ss_ticket_number AS order_id,
            d.d_date AS order_date,
            c.c_first_name || ' ' || c.c_last_name AS customer_name,
            cd.cd_gender AS gender,
            NULL AS department,
            NULL AS warehouse_name,
            ss.ss_quantity AS quantity,
            ss.ss_ext_sales_price AS sales_amount,
            ss.ss_net_paid AS net_paid,
            CASE
                WHEN ss.ss_quantity > 10 THEN 'Bulk'
                WHEN ss.ss_quantity BETWEEN 5 AND 10 THEN 'Medium'
                ELSE 'Small'
            END AS order_size,
            ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY d.d_date DESC) AS rn_customer_latest,
            p.p_promo_name,
            0 AS return_cnt
        FROM tpcds.store_sales ss
        JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
        JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE d.d_year = 2001
          AND s.s_state = 'CA'
          AND cd.cd_gender = 'M'
          AND p.p_discount_active = 'Y'
          AND ss.ss_ext_sales_price > 500
    ),
    -- Web sales – another channel
    web_sales_pre AS (
        SELECT
            ws.ws_order_number AS order_id,
            d.d_date AS order_date,
            c.c_first_name || ' ' || c.c_last_name AS customer_name,
            cd.cd_gender AS gender,
            NULL AS department,
            w.w_warehouse_name AS warehouse_name,
            ws.ws_quantity AS quantity,
            ws.ws_ext_sales_price AS sales_amount,
            ws.ws_net_paid AS net_paid,
            CASE
                WHEN ws.ws_quantity > 10 THEN 'Bulk'
                WHEN ws.ws_quantity BETWEEN 5 AND 10 THEN 'Medium'
                ELSE 'Small'
            END AS order_size,
            ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY d.d_date DESC) AS rn_customer_latest,
            p.p_promo_name,
            (SELECT COUNT(*) FROM tpcds.catalog_returns cr WHERE cr.cr_order_number = ws.ws_order_number) AS return_cnt,
            ws.ws_web_site_sk
        FROM tpcds.web_sales ws
        JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN tpcds.time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
        JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
        WHERE d.d_year = 2001
          AND we.web_state = 'CA'
          AND p.p_discount_active = 'Y'
          AND ws.ws_ext_sales_price > 800
    ),
    -- Collect distinct order keys from all channels
    sales_keys AS (
        SELECT order_id FROM catalog_sales_pre
        UNION
        SELECT order_id FROM store_sales_pre
        UNION
        SELECT order_id FROM web_sales_pre
    ),
    -- Orders that have a return (filtered by reason & year)
    return_keys AS (
        SELECT cr.cr_order_number AS order_id
        FROM tpcds.catalog_returns cr
        JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND r.r_reason_desc LIKE '%defective%'
    ),
    -- Orders that survived the return filter
    valid_orders AS (
        SELECT order_id FROM sales_keys
        EXCEPT
        SELECT order_id FROM return_keys
    ),
    -- Union all channel data, keeping only the latest row per customer and only valid orders
    all_sales AS (
        SELECT
            cs.order_id,
            cs.order_date,
            cs.customer_name,
            cs.gender,
            cs.department,
            cs.warehouse_name,
            cs.quantity,
            cs.sales_amount,
            cs.net_paid,
            cs.order_size,
            cs.rn_customer_latest,
            cs.p_promo_name,
            cs.return_cnt,
            cs.inventory_on_hand
        FROM catalog_sales_pre cs
        WHERE cs.rn_customer_latest = 1
          AND cs.order_id IN (SELECT order_id FROM valid_orders)

        UNION ALL

        SELECT
            ss.order_id,
            ss.order_date,
            ss.customer_name,
            ss.gender,
            ss.department,
            ss.warehouse_name,
            ss.quantity,
            ss.sales_amount,
            ss.net_paid,
            ss.order_size,
            ss.rn_customer_latest,
            ss.p_promo_name,
            ss.return_cnt,
            NULL AS inventory_on_hand
        FROM store_sales_pre ss
        WHERE ss.rn_customer_latest = 1
          AND ss.order_id IN (SELECT order_id FROM valid_orders)

        UNION ALL

        SELECT
            ws.order_id,
            ws.order_date,
            ws.customer_name,
            ws.gender,
            ws.department,
            ws.warehouse_name,
            ws.quantity,
            ws.sales_amount,
            ws.net_paid,
            ws.order_size,
            ws.rn_customer_latest,
            ws.p_promo_name,
            ws.return_cnt,
            NULL AS inventory_on_hand
        FROM web_sales_pre ws
        WHERE ws.rn_customer_latest = 1
          AND ws.order_id IN (SELECT order_id FROM valid_orders)
    )
SELECT
    order_id,
    order_date,
    customer_name,
    gender,
    department,
    warehouse_name,
    SUM(quantity) AS total_quantity,
    SUM(sales_amount) AS total_sales,
    SUM(net_paid) AS total_net_paid,
    MAX(order_size) AS order_size,
    CASE
        WHEN SUM(sales_amount) > 5000 THEN 'High'
        WHEN SUM(sales_amount) BETWEEN 2000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    MAX(inventory_on_hand) AS latest_inventory_on_hand
FROM all_sales
GROUP BY
    order_id,
    order_date,
    customer_name,
    gender,
    department,
    warehouse_name
HAVING SUM(sales_amount) > 2000
ORDER BY total_sales DESC
LIMIT 100
