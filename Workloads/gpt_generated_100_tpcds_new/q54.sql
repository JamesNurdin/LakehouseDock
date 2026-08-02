WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    d_main.d_date,
    w.w_warehouse_sk,
    w.w_warehouse_name,
    w.w_state,
    sm.sm_type               AS ship_mode_type,
    ib.ib_upper_bound,
    SUM(ss.ss_net_paid)      AS store_sales_net,
    SUM(cs.cs_net_paid)      AS catalog_sales_net,
    SUM(wr.wr_return_amt)    AS web_return_amount,
    CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank,
    inv_agg.total_qty
FROM date_dim d_main
JOIN store_sales ss
     ON ss.ss_sold_date_sk = d_main.d_date_sk
JOIN time_dim t_ss
     ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN household_demographics hd_ss
     ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN income_band ib
     ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs
     ON cs.cs_sold_date_sk = d_main.d_date_sk
JOIN time_dim t_cs
     ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN household_demographics hd_cs
     ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_date_sk = d_main.d_date_sk
JOIN web_returns wr
     ON wr.wr_returned_date_sk = d_main.d_date_sk
JOIN time_dim t_wr
     ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN household_demographics hd_wr
     ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
JOIN web_site ws
     ON ws.web_open_date_sk = d_main.d_date_sk
LEFT JOIN store_returns sr
     ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d_main.d_date_sk
LEFT JOIN inv_agg
     ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
        AND inv_agg.inv_date_sk = d_main.d_date_sk
WHERE sr.sr_ticket_number IS NULL
  AND d_main.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND ib.ib_upper_bound > 150000
  AND w.w_state = 'CA'
GROUP BY
    d_main.d_date,
    w.w_warehouse_sk,
    w.w_warehouse_name,
    w.w_state,
    sm.sm_type,
    ib.ib_upper_bound,
    inv_agg.total_qty
HAVING SUM(ss.ss_net_paid) > 5000
ORDER BY store_sales_net DESC
LIMIT 100
