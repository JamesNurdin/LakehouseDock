WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_sold_date_sk,
        cs.cs_bill_addr_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        CASE 
            WHEN SUM(cs.cs_net_paid) > 10000 THEN 'HIGH'
            ELSE 'LOW'
        END AS net_paid_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND c.c_first_name = 'Javier'
      AND ib.ib_upper_bound = 180000
      AND hd.hd_vehicle_count >= 2
    GROUP BY cs.cs_bill_customer_sk, cs.cs_sold_date_sk, cs.cs_bill_addr_sk
)
SELECT
    sa.cs_bill_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    d.d_date,
    sa.total_net_paid,
    sa.total_sales,
    sa.order_cnt,
    sa.net_paid_category,
    ws.ws_net_paid AS web_net_paid,
    ws.ws_net_profit,
    sm.sm_type,
    w.w_warehouse_name,
    inv.inv_quantity_on_hand,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    rs.r_reason_desc,
    wsit.web_name AS website_name
FROM sales_agg sa
JOIN customer c ON sa.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d ON sa.cs_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN reason rs ON wr.wr_reason_sk = rs.r_reason_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE EXISTS (
    SELECT 1 FROM web_page wp
    WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
      AND wp.wp_type = 'article'
)
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
ORDER BY sa.total_net_paid DESC
LIMIT 100
