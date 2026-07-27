WITH joined_data AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_state,
        cc.cc_name,
        cs.cs_net_paid,
        cs.cs_order_number,
        ws.ws_net_paid,
        ws.ws_order_number,
        sr.sr_return_amt,
        wr.wr_return_amt,
        i.inv_quantity_on_hand,
        p.p_discount_active
    FROM
        date_dim d
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t3 ON ws.ws_sold_time_sk = t3.t_time_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                             AND wr.wr_order_number = ws.ws_order_number
        JOIN time_dim t4 ON wr.wr_returned_time_sk = t4.t_time_sk
)
SELECT
    d_year,
    s_store_id,
    s_state,
    CASE WHEN s_state = 'WA' THEN 'West' ELSE 'Other' END AS region_category,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(wr_return_amt) AS total_web_returns,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ws_order_number) AS distinct_web_orders
FROM joined_data
GROUP BY
    d_year,
    s_store_id,
    s_state,
    CASE WHEN s_state = 'WA' THEN 'West' ELSE 'Other' END
ORDER BY total_catalog_sales DESC
LIMIT 100
