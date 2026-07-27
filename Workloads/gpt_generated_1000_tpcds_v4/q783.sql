WITH distinct_customers AS (
    SELECT DISTINCT c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
),
cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ship_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        d_sold.d_year,
        cp.cp_department,
        p.p_channel_press,
        hd_bill.hd_vehicle_count,
        cc.cc_state
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN distinct_customers dc ON cs.cs_bill_customer_sk = dc.c_customer_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d_sold.d_year = 2001
      AND cp.cp_type = 'A'
      AND p.p_channel_press = 'N'
      AND hd_bill.hd_vehicle_count >= 2
      AND cc.cc_state = 'TX'
)
SELECT
    cs.d_year,
    s.s_state,
    cs.cp_department,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_profit,
    MIN(cs.cs_quantity) AS min_qty,
    MAX(cs.cs_quantity) AS max_qty
FROM cs
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = cs.cs_bill_customer_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE wp.wp_link_count > 10
  AND s.s_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_item_sk = cs.cs_item_sk
          AND i.inv_quantity_on_hand > 0
    )
GROUP BY cs.d_year, s.s_state, cs.cp_department
ORDER BY total_sales DESC
LIMIT 100
