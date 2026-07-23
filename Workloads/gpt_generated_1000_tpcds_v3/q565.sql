WITH filtered_dates AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq,
           d_day_name,
           d_holiday,
           d_date
    FROM date_dim
    WHERE d_year = 2002
      AND d_month_seq BETWEEN 1 AND 12
      AND d_holiday = 'N'
      AND d_day_name IN ('Monday', 'Tuesday', 'Wednesday')
)
SELECT
    fd.d_year,
    fd.d_month_seq,
    fd.d_day_name,
    w.w_warehouse_name,
    CASE WHEN ws.ws_net_profit > 200 THEN 'High' ELSE 'Low' END AS profit_category,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(sr.sr_fee) AS total_store_return_fees,
    SUM(cr.cr_fee) AS total_catalog_return_fees,
    MIN(inv.inv_quantity_on_hand) AS min_inventory_qty,
    MAX(st.s_number_employees) AS max_store_employees,
    (
        SELECT AVG(hd_sub.hd_vehicle_count)
        FROM household_demographics hd_sub
        WHERE hd_sub.hd_income_band_sk = 5
    ) AS avg_vehicle_count_income5
FROM filtered_dates fd
LEFT JOIN web_sales ws
       ON ws.ws_sold_date_sk = fd.d_date_sk
LEFT JOIN store_returns sr
       ON sr.sr_returned_date_sk = fd.d_date_sk
LEFT JOIN catalog_returns cr
       ON cr.cr_returned_date_sk = fd.d_date_sk
LEFT JOIN inventory inv
       ON inv.inv_date_sk = fd.d_date_sk
LEFT JOIN store st
       ON st.s_closed_date_sk = fd.d_date_sk
LEFT JOIN warehouse w
       ON w.w_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN household_demographics hd
       ON hd.hd_demo_sk = ws.ws_bill_hdemo_sk
WHERE ws.ws_sales_price > 100
  AND inv.inv_quantity_on_hand > 500
  AND w.w_state = 'TX'
  AND st.s_state = 'CA'
  AND sr.sr_return_tax < 5
GROUP BY
    fd.d_year,
    fd.d_month_seq,
    fd.d_day_name,
    w.w_warehouse_name,
    CASE WHEN ws.ws_net_profit > 200 THEN 'High' ELSE 'Low' END
ORDER BY total_net_paid DESC
LIMIT 100
