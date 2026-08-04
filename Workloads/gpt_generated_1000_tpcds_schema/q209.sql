WITH cs_agg AS (
    SELECT
        cp.cp_department AS department,
        sm.sm_type AS ship_type,
        t1.t_am_pm AS am_pm,
        CASE WHEN cs.cs_ext_discount_amt > 1000 THEN 'High' ELSE 'Low' END AS discount_category,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        SUM(p.p_cost) AS total_promo_cost,
        SUM(w.w_warehouse_sq_ft) AS total_warehouse_sqft,
        COUNT(DISTINCT ca_bill.ca_zip) AS distinct_bill_zip,
        AVG(hd_bill.hd_income_band_sk) AS avg_income_band,
        CAST(NULL AS decimal(7,2)) AS total_return_amt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    GROUP BY cp.cp_department,
             sm.sm_type,
             t1.t_am_pm,
             CASE WHEN cs.cs_ext_discount_amt > 1000 THEN 'High' ELSE 'Low' END
),
ws_agg AS (
    SELECT
        CAST(NULL AS varchar) AS department,
        sm.sm_type AS ship_type,
        t2.t_am_pm AS am_pm,
        CASE WHEN ws.ws_ext_discount_amt > 1000 THEN 'High' ELSE 'Low' END AS discount_category,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
        SUM(p_ws.p_cost) AS total_promo_cost,
        SUM(w_ws.w_warehouse_sq_ft) AS total_warehouse_sqft,
        COUNT(DISTINCT ca_ws_bill.ca_zip) AS distinct_bill_zip,
        AVG(hd_ws_bill.hd_income_band_sk) AS avg_income_band,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_sales ws
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    GROUP BY sm.sm_type,
             t2.t_am_pm,
             CASE WHEN ws.ws_ext_discount_amt > 1000 THEN 'High' ELSE 'Low' END
)
SELECT
    department,
    ship_type,
    am_pm,
    discount_category,
    SUM(total_net_paid) AS sum_net_paid,
    SUM(orders_cnt) AS sum_orders,
    SUM(total_promo_cost) AS sum_promo_cost,
    SUM(total_warehouse_sqft) AS sum_warehouse_sqft,
    SUM(distinct_bill_zip) AS sum_distinct_bill_zip,
    AVG(avg_income_band) AS avg_income_band,
    SUM(total_return_amt) AS sum_return_amount
FROM (
    SELECT * FROM cs_agg
    UNION DISTINCT
    SELECT * FROM ws_agg
) u
GROUP BY department, ship_type, am_pm, discount_category
ORDER BY sum_net_paid DESC
LIMIT 100
