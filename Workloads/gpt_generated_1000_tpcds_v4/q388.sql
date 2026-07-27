WITH avg_store_profit_cte AS (
    SELECT avg(ss2.ss_net_profit) AS avg_profit
    FROM store_sales ss2
)
SELECT
    d_date.d_year AS sales_year,
    wsite.web_name,
    cp.cp_department,
    wp.wp_type,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
    ap.avg_profit AS avg_store_profit
FROM store_sales ss
JOIN date_dim d_date
    ON ss.ss_sold_date_sk = d_date.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_date.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_date.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_ws_open
    ON wsite.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close
    ON wsite.web_close_date_sk = d_ws_close.d_date_sk
CROSS JOIN avg_store_profit_cte ap
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = ws.ws_order_number
      AND cr2.cr_return_amount > 0
)
GROUP BY
    d_date.d_year,
    wsite.web_name,
    cp.cp_department,
    wp.wp_type,
    ap.avg_profit
HAVING
    SUM(ss.ss_net_paid) > 50000
ORDER BY
    d_date.d_year DESC,
    total_net_paid DESC
LIMIT 100
