WITH
    inventory_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        WHERE inv_quantity_on_hand > 0
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    catalog_returns_agg AS (
        SELECT
            cr.cr_order_number,
            SUM(cr.cr_return_amount) AS total_return_amount,
            SUM(cr.cr_net_loss) AS total_net_loss
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        WHERE i.i_category = 'Sports'
          AND cp.cp_department = 'Electronics'
          AND sm.sm_type = 'AIR'
          AND w.w_state = 'TX'
          AND t.t_hour BETWEEN 8 AND 20
          AND cr.cr_return_amount > 0
        GROUP BY cr.cr_order_number
    ),
    catalog_agg AS (
        SELECT
            cs.cs_order_number AS order_number,
            i.i_item_id,
            i.i_product_name,
            cp.cp_department AS channel,
            SUM(cs.cs_net_paid_inc_tax) AS total_sales,
            SUM(cs.cs_net_profit) AS total_profit,
            cragg.total_return_amount,
            cragg.total_net_loss,
            RANK() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs.cs_net_paid_inc_tax) DESC) AS sales_rank,
            CASE WHEN SUM(cs.cs_net_paid_inc_tax) > 50000 THEN 'High' ELSE 'Medium' END AS sales_category,
            (
                SELECT COUNT(*)
                FROM catalog_returns cr2
                WHERE cr2.cr_order_number = cs.cs_order_number
            ) AS return_line_count
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN inventory_agg ia ON i.i_item_sk = ia.inv_item_sk AND w.w_warehouse_sk = ia.inv_warehouse_sk
        LEFT JOIN catalog_returns_agg cragg ON cs.cs_order_number = cragg.cr_order_number
        WHERE cp.cp_department = 'Books'
          AND ca.ca_state = 'CA'
          AND p.p_purpose = 'Unknown'
          AND t.t_hour BETWEEN 9 AND 17
          AND cs.cs_quantity >= 1
          AND cs.cs_net_paid_inc_tax > 1000
        GROUP BY
            cs.cs_order_number,
            i.i_item_id,
            i.i_product_name,
            cp.cp_department,
            cragg.total_return_amount,
            cragg.total_net_loss
    ),
    web_agg AS (
        SELECT
            ws.ws_order_number AS order_number,
            i.i_item_id,
            i.i_product_name,
            s.web_name AS channel,
            SUM(ws.ws_net_paid_inc_tax) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit,
            CAST(NULL AS decimal(7,2)) AS total_return_amount,
            CAST(NULL AS decimal(7,2)) AS total_net_loss,
            RANK() OVER (PARTITION BY s.web_name ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank,
            CASE WHEN SUM(ws.ws_net_paid_inc_tax) > 20000 THEN 'High' ELSE 'Low' END AS sales_category,
            CAST(NULL AS integer) AS return_line_count
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE s.web_country = 'United States'
          AND ca.ca_state = 'NY'
          AND p.p_purpose = 'Unknown'
          AND t.t_hour BETWEEN 10 AND 18
          AND ws.ws_quantity >= 2
          AND ws.ws_net_paid_inc_tax > 5000
        GROUP BY
            ws.ws_order_number,
            i.i_item_id,
            i.i_product_name,
            s.web_name
    )
SELECT
    order_number,
    i_item_id,
    i_product_name,
    channel,
    total_sales,
    total_profit,
    total_return_amount,
    total_net_loss,
    sales_rank,
    sales_category,
    return_line_count
FROM catalog_agg
UNION ALL
SELECT
    order_number,
    i_item_id,
    i_product_name,
    channel,
    total_sales,
    total_profit,
    total_return_amount,
    total_net_loss,
    sales_rank,
    sales_category,
    return_line_count
FROM web_agg
