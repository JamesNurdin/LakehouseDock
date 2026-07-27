WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_net_paid)      AS total_net_paid,
        SUM(ws.ws_net_profit)    AS total_net_profit
    FROM tpcds.web_sales ws
    GROUP BY
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_item_sk,
        ws.ws_order_number
),
store_ret_agg AS (
    SELECT
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt) AS total_store_return
    FROM tpcds.store_returns sr
    GROUP BY sr.sr_returned_date_sk
)
SELECT
    ws_site.web_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    sa.total_net_paid,
    sa.total_net_profit,
    CASE WHEN sa.total_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (PARTITION BY d_sales.d_year ORDER BY sa.total_net_profit DESC) AS profit_rank,
    w.w_city,
    cc.cc_name,
    cp.cp_department,
    sra.total_store_return,
    SUM(wr.wr_refunded_cash) OVER (PARTITION BY ws_site.web_site_sk) AS site_refunded_cash
FROM sales_agg sa
JOIN tpcds.web_site ws_site
    ON sa.ws_web_site_sk = ws_site.web_site_sk
JOIN tpcds.warehouse w
    ON sa.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.date_dim d_sales
    ON sa.ws_sold_date_sk = d_sales.d_date_sk
JOIN tpcds.call_center cc
    ON cc.cc_open_date_sk = d_sales.d_date_sk
JOIN tpcds.catalog_page cp
    ON cp.cp_start_date_sk = d_sales.d_date_sk
LEFT JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = sa.ws_item_sk
   AND wr.wr_order_number = sa.ws_order_number
LEFT JOIN tpcds.date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN tpcds.customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN tpcds.customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
LEFT JOIN store_ret_agg sra
    ON sra.sr_returned_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2001
  AND d_sales.d_day_name = 'Monday'
  AND d_return.d_holiday = 'N'
  AND cc.cc_gmt_offset BETWEEN -5 AND 0
  AND w.w_state = 'CA'
  AND ws_site.web_tax_percentage > 0.05
ORDER BY profit_rank ASC, sa.total_net_profit DESC
LIMIT 100
