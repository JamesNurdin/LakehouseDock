WITH sales_by_site AS (
    SELECT
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid) AS site_total_net_paid,
        SUM(ws.ws_ext_sales_price) AS site_total_ext_sales,
        COUNT(*) AS site_order_count
    FROM web_sales ws
    JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
    WHERE td_ws.t_hour BETWEEN 9 AND 17
      AND ws.ws_ext_wholesale_cost > 1000
    GROUP BY ws.ws_web_site_sk
)
SELECT
    cc.cc_name,
    w_cr.w_warehouse_name AS return_warehouse_name,
    COALESCE(w_ws.w_warehouse_name, 'UNKNOWN') AS ship_warehouse_name,
    r_sr.r_reason_desc,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    ws.ws_order_number,
    ws.ws_net_paid,
    sb.site_total_net_paid,
    ws.ws_net_paid / avg_nb.avg_net_paid AS net_paid_ratio,
    CASE
        WHEN ws.ws_net_paid > (sb.site_total_net_paid / NULLIF(sb.site_order_count, 0)) THEN 'Above Avg Site'
        ELSE 'Below Avg Site'
    END AS site_performance,
    ROW_NUMBER() OVER (ORDER BY cr.cr_return_amount DESC) AS rn
FROM store_returns sr
JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_returns cr ON cr.cr_returned_time_sk = td_sr.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = td_sr.t_time_sk
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN sales_by_site sb ON ws.ws_web_site_sk = sb.ws_web_site_sk
CROSS JOIN (SELECT AVG(ws2.ws_net_paid) AS avg_net_paid FROM web_sales ws2) avg_nb
WHERE cc.cc_country = 'United States'
  AND td_ws.t_hour BETWEEN 9 AND 17
  AND ws.ws_ext_wholesale_cost > 1000
  AND r_sr.r_reason_desc IS NOT NULL
ORDER BY rn
LIMIT 100
