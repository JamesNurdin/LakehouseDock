WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_tax,
        cs.cs_quantity AS cs_quantity,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_hdemo_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_hdemo_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_hdemo_sk,
        d.d_year,
        d.d_date,
        t.t_hour,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        sm.sm_type,
        w.w_state,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
)
SELECT
    d_year,
    sm_type,
    hd_income_band_sk,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ws_net_paid) AS total_web_net_paid,
    SUM(ss_net_paid) AS total_store_net_paid,
    SUM(cs_quantity + ws_quantity + ss_quantity) AS total_quantity,
    CASE
        WHEN SUM(cs_net_paid + ws_net_paid + ss_net_paid) > 100000 THEN 'HIGH'
        WHEN SUM(cs_net_paid + ws_net_paid + ss_net_paid) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS revenue_category
FROM joined_data
WHERE d_year BETWEEN 1998 AND 2000
  AND sm_type = 'AIR'
  AND w_state = 'CA'
  AND hd_dep_count <= 5
  AND inv_quantity_on_hand > 100
  AND cs_quantity > 5
  AND ws_quantity > 3
GROUP BY d_year, sm_type, hd_income_band_sk
HAVING SUM(cs_net_paid + ws_net_paid + ss_net_paid) > 20000
ORDER BY total_catalog_net_paid DESC
LIMIT 100
