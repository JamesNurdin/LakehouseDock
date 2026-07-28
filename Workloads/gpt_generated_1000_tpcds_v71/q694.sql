WITH sales_summary AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        cc.cc_name,
        cp.cp_type,
        p.p_promo_name,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_net_paid_inc_ship > 500
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND EXISTS (
            SELECT 1 FROM web_returns wr
            JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
            WHERE wr.wr_order_number = cs.cs_order_number
              AND wr.wr_returned_date_sk = d.d_date_sk
              AND r.r_reason_desc = 'Customer Not Satisfied'
      )
    GROUP BY d.d_year, w.w_warehouse_name, cc.cc_name, cp.cp_type, p.p_promo_name
)
SELECT
    d_year,
    w_warehouse_name,
    cc_name,
    cp_type,
    p_promo_name,
    total_sales,
    total_returns,
    total_inventory,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank,
    CASE WHEN total_sales > 10000 THEN 'High' ELSE 'Low' END AS sales_category
FROM sales_summary
ORDER BY total_sales DESC
LIMIT 100
