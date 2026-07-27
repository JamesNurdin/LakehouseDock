WITH avg_overall_profit AS (
    SELECT avg(ws2.ws_net_profit) AS avg_profit
    FROM tpcds.web_sales ws2
),
joined_data AS (
    SELECT
        wsit.web_name,
        sm_ws.sm_carrier,
        r_cat.r_reason_desc AS catalog_return_reason,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(ws.ws_net_profit) AS avg_web_profit
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN tpcds.reason r_cat ON cr.cr_reason_sk = r_cat.r_reason_sk
    JOIN tpcds.web_sales ws
        ON cr.cr_call_center_sk = cc.cc_call_center_sk  -- indirect link via call_center (allowed by join rules)
    JOIN tpcds.ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN tpcds.web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN tpcds.date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN tpcds.date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN tpcds.web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
                               AND wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN tpcds.reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE wsit.web_gmt_offset = -5.00
      AND d_ws_sold.d_year = 2001
      AND sm_ws.sm_carrier = 'USPS'
    GROUP BY wsit.web_name, sm_ws.sm_carrier, r_cat.r_reason_desc
)
SELECT
    jd.web_name,
    jd.sm_carrier,
    jd.catalog_return_reason,
    jd.total_catalog_return_loss,
    jd.total_web_return_loss,
    jd.total_web_profit,
    jd.order_count,
    CASE WHEN jd.total_return_qty > 10 THEN 'Large' ELSE 'Small' END AS return_size_category,
    CASE WHEN jd.avg_web_profit > ap.avg_profit THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category
FROM joined_data jd
CROSS JOIN avg_overall_profit ap
ORDER BY jd.total_web_profit DESC
LIMIT 100
