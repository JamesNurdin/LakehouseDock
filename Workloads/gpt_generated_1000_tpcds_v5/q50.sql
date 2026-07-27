WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        sm.sm_ship_mode_id,
        wp.wp_type,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        SUM(cs.cs_net_paid) AS total_cs_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS ws_order_cnt,
        COUNT(DISTINCT cs.cs_order_number) AS cs_order_cnt,
        SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_quantity ELSE 0 END) AS total_return_qty
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE wp.wp_rec_start_date >= DATE '1999-01-01'
      AND wp.wp_rec_end_date <= DATE '2001-12-31'
      AND sm.sm_type = 'AIR'
      AND ws.ws_ext_discount_amt > 5000
      AND cs.cs_quantity > 5
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_id, sm.sm_ship_mode_id, wp.wp_type
)
SELECT
    s.c_customer_id,
    s.sm_ship_mode_id,
    s.wp_type,
    s.total_ws_net_paid,
    s.total_cs_net_paid,
    s.total_ws_net_paid + s.total_cs_net_paid AS combined_net_paid,
    s.total_return_qty,
    (s.total_ws_net_paid + s.total_cs_net_paid) / NULLIF(s.ws_order_cnt + s.cs_order_cnt, 0) AS avg_net_paid_per_order,
    (SELECT AVG(ws2.ws_ext_discount_amt) FROM web_sales ws2 WHERE ws2.ws_ext_discount_amt > 0) AS overall_avg_discount
FROM sales_agg s
WHERE (s.total_ws_net_paid + s.total_cs_net_paid) > 100000
ORDER BY combined_net_paid DESC
LIMIT 100
