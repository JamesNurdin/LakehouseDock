SELECT
    cp.cp_department,
    wsite.web_name,
    r.r_reason_desc,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    AVG(CASE WHEN td.t_hour BETWEEN 12 AND 23 THEN ss.ss_net_paid END) AS avg_evening_net_paid,
    SUM(CASE WHEN r.r_reason_desc = 'Customer Not Satisfied' THEN cr.cr_return_amount ELSE 0 END) AS total_unsat_return_amount
FROM store_sales ss
JOIN time_dim td
  ON ss.ss_sold_time_sk = td.t_time_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr
  ON cr.cr_returned_time_sk = td.t_time_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr
  ON wr.wr_returned_time_sk = td.t_time_sk
  AND wr.wr_order_number = ws.ws_order_number
WHERE td.t_am_pm = 'PM'
  AND hd.hd_vehicle_count >= 2
  AND wsite.web_state = 'CA'
  AND r.r_reason_sk IN (
        SELECT DISTINCT cr2.cr_reason_sk
        FROM catalog_returns cr2
        WHERE cr2.cr_return_quantity > 1
    )
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_net_loss > 50
    )
GROUP BY
    cp.cp_department,
    wsite.web_name,
    r.r_reason_desc
ORDER BY total_store_profit DESC
LIMIT 100
