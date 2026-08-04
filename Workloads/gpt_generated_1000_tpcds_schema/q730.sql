WITH sales_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_color,
        i.i_current_price,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_order_number,
        CASE WHEN cs.cs_ext_discount_amt > 0 THEN 'Discounted' ELSE 'Full Price' END AS price_type,
        cc.cc_state,
        p.p_channel_details,
        wp.wp_url,
        ws.web_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wp.wp_customer_sk = cust.c_customer_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'pink'
      AND cc.cc_state = 'CA'
      AND p.p_channel_details LIKE 'Companies shall not pr%'
      AND ws.web_name = 'Online Store'
),
inventory_data AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_color,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        CASE WHEN inv.inv_quantity_on_hand = 0 THEN 'Out of Stock' ELSE 'In Stock' END AS stock_status,
        cc.cc_state,
        wp.wp_url
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    FULL OUTER JOIN call_center cc ON d.d_date_sk = cc.cc_open_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'pink'
      AND cc.cc_state = 'CA'
),
union_data AS (
    SELECT d_year, i_category, i_color, price_type AS type, SUM(cs_ext_sales_price) AS metric
    FROM sales_data
    GROUP BY d_year, i_category, i_color, price_type
    UNION
    SELECT d_year, i_category, i_color, stock_status AS type, SUM(inv_quantity_on_hand) AS metric
    FROM inventory_data
    GROUP BY d_year, i_category, i_color, stock_status
)
SELECT
    d_year,
    i_category,
    i_color,
    type,
    SUM(metric) AS total_metric,
    COUNT(*) AS rows_count
FROM union_data
GROUP BY d_year, i_category, i_color, type
ORDER BY total_metric DESC
LIMIT 100
