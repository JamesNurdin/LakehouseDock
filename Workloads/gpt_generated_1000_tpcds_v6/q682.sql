WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price)   AS total_sales,
        SUM(ss_net_profit)        AS total_profit
    FROM store_sales
    GROUP BY ss_customer_sk, ss_sold_date_sk
)
SELECT
    c.c_customer_id,
    d_s.d_date,
    d_s.d_year,
    cd.cd_gender,
    hd.hd_vehicle_count,
    cc.cc_name,
    cp.cp_department,
    wr_reason.r_reason_desc                AS web_return_reason,
    cr_reason.r_reason_desc                AS catalog_return_reason,
    w.w_warehouse_name,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ss_agg.total_sales,
    ss_agg.total_profit,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ss_agg.total_sales DESC) AS sales_rank,
    RANK()      OVER (ORDER BY ss_agg.total_profit DESC)                     AS profit_rank,
    CASE WHEN ss_agg.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END    AS profit_status
FROM ss_agg
JOIN customer c
    ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN date_dim d_s
    ON ss_agg.ss_sold_date_sk = d_s.d_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN web_sales ws
    ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim d_ws
    ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason wr_reason
    ON wr.wr_reason_sk = wr_reason.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_s.d_date_sk
JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason cr_reason
    ON cr.cr_reason_sk = cr_reason.r_reason_sk
WHERE d_s.d_year = 2001
  AND cd.cd_gender = 'M'
  AND hd.hd_vehicle_count >= 1
  AND w.w_state = 'CA'
  AND t_ws.t_hour BETWEEN 9 AND 17
ORDER BY ss_agg.total_sales DESC
LIMIT 100
