WITH filtered AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_web_site_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_wholesale_cost,
        ws.ws_coupon_amt,
        ws.ws_quantity,
        td.t_shift,
        td.t_hour,
        wsit.web_name,
        wsit.web_state,
        wsit.web_zip,
        wsit.web_street_type,
        wsit.web_rec_end_date
    FROM tpcds.web_sales ws
    JOIN tpcds.time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN tpcds.web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE td.t_shift = 'first'
      AND td.t_time >= 8
      AND wsit.web_rec_end_date >= DATE '2000-01-01'
      AND wsit.web_rec_end_date <= DATE '2001-12-31'
      AND wsit.web_zip IN ('95804', '14593')
      AND wsit.web_street_type = 'Street'
      AND ws.ws_wholesale_cost > 40
      AND ws.ws_coupon_amt < 100
)
SELECT
    web_name,
    t_shift,
    t_hour,
    COUNT(*) AS order_count,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_ext_sales_price) AS avg_sales,
    MIN(ws_ext_sales_price) AS min_sales,
    MAX(ws_ext_sales_price) AS max_sales,
    SUM(ws_net_profit) AS total_profit
FROM filtered
GROUP BY web_name, t_shift, t_hour
ORDER BY total_sales DESC
LIMIT 100
