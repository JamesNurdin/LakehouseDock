WITH sales_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_time_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk
    FROM web_sales ws
),
agg AS (
    SELECT
        wh.w_warehouse_name,
        wsit.web_name,
        td_s.t_shift,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(sales.ws_ext_sales_price) AS total_sales,
        SUM(sales.ws_net_profit) AS total_profit,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_cr_returns,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_sr_returns,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_wr_returns,
        COUNT(DISTINCT sales.ws_order_number) AS distinct_orders,
        CASE
            WHEN SUM(sales.ws_net_profit) -
                 SUM(COALESCE(cr.cr_return_amount, 0)) -
                 SUM(COALESCE(sr.sr_return_amt, 0)) -
                 SUM(COALESCE(wr.wr_return_amt, 0)) > 0
            THEN 'Overall Profit' ELSE 'Overall Loss'
        END AS overall_status,
        RANK() OVER (ORDER BY SUM(sales.ws_net_profit) DESC) AS profit_rank
    FROM sales_base sales
    JOIN time_dim td_s
        ON sales.ws_sold_time_sk = td_s.t_time_sk
    JOIN warehouse wh
        ON sales.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_site wsit
        ON sales.ws_web_site_sk = wsit.web_site_sk
    JOIN customer_demographics cd
        ON sales.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sales.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td_s.t_time_sk
        AND cr.cr_warehouse_sk = wh.w_warehouse_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN time_dim td_cr
        ON cr.cr_returned_time_sk = td_cr.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = td_s.t_time_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = td_s.t_time_sk
        AND wr.wr_item_sk = sales.ws_item_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    GROUP BY
        wh.w_warehouse_name,
        wsit.web_name,
        td_s.t_shift,
        cd.cd_gender,
        hd.hd_income_band_sk
)
SELECT
    *,
    SUM(total_profit) OVER (PARTITION BY w_warehouse_name) AS profit_by_warehouse
FROM agg
ORDER BY total_profit DESC
LIMIT 100
