WITH catalog_data AS (
    SELECT
        d.d_year AS year,
        sm.sm_carrier AS source_name,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_quantity) AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier = 'DHL'
      AND cc.cc_state = 'CA'
      AND r.r_reason_id = 'REASON_15'
      AND w.w_state = 'CA'
      AND cs.cs_quantity > 5
    GROUP BY d.d_year, sm.sm_carrier
    HAVING SUM(cs.cs_net_paid) > 1000
),
store_web_data AS (
    SELECT
        d.d_year AS year,
        s.s_store_name AS source_name,
        SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) AS net_paid,
        SUM(ss.ss_quantity) + SUM(ws.ws_quantity) AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c1 ON ss.ss_customer_sk = c1.c_customer_sk
    JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND wsit.web_country = 'United States'
      AND sm.sm_carrier = 'USPS'
      AND w.w_state = 'CA'
      AND ss.ss_quantity > 3
    GROUP BY d.d_year, s.s_store_name
    HAVING SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 500
)
SELECT DISTINCT year, source_name, net_paid, quantity
FROM catalog_data
UNION
SELECT DISTINCT year, source_name, net_paid, quantity
FROM store_web_data
ORDER BY net_paid DESC
LIMIT 100
