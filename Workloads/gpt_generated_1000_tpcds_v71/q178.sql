WITH
ws AS (
    SELECT
        ws.ws_order_number,
        d_ws.d_year AS year,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_item_sk,
        p.p_channel_dmail,
        p.p_channel_tv
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
sr AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_amt,
        d_sr.d_year AS sr_year
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
),
wr AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        d_wr.d_year AS wr_year
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN item i_wr ON wr.wr_item_sk = i_wr.i_item_sk
),
cc AS (
    SELECT
        cc.cc_name,
        cc.cc_class,
        d_cc_open.d_year AS cc_year
    FROM call_center cc
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_close ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
),
cp AS (
    SELECT
        cp.cp_department,
        d_cp_start.d_year AS cp_year
    FROM catalog_page cp
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
)
SELECT
    ws.year,
    ws.p_channel_dmail,
    ws.p_channel_tv,
    cc.cc_class,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM ws
LEFT JOIN sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.year = sr.sr_year
LEFT JOIN wr ON ws.ws_order_number = wr.wr_order_number AND ws.year = wr.wr_year
LEFT JOIN cc ON ws.year = cc.cc_year
LEFT JOIN cp ON ws.year = cp.cp_year
GROUP BY
    ws.year,
    ws.p_channel_dmail,
    ws.p_channel_tv,
    cc.cc_class
ORDER BY total_sales DESC
LIMIT 100
