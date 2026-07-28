WITH cs AS (
    SELECT cs.*
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_department = 'Electronics'
)
SELECT
    d1.d_year,
    d1.d_month_seq,
    we.web_site_id,
    SUM(cs.cs_net_paid)                         AS total_catalog_sales,
    COUNT(DISTINCT cs.cs_order_number)          AS distinct_catalog_orders,
    SUM(ss.ss_net_paid)                         AS total_store_sales,
    SUM(ws.ws_net_paid)                         AS total_web_sales,
    SUM(cr.cr_return_amount)                    AS total_catalog_returns,
    SUM(sr.sr_return_amt)                       AS total_store_returns,
    SUM(wr.wr_return_amt)                       AS total_web_returns
FROM cs
JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_date_sk = d1.d_date_sk
                AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                        AND cr.cr_item_sk = cs.cs_item_sk
JOIN household_demographics hd1 ON cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d1.d_date_sk
                    AND ss.ss_sold_time_sk = t1.t_time_sk
JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                     AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
                  AND ws.ws_sold_time_sk = t1.t_time_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
JOIN time_dim t3 ON wr.wr_returned_time_sk = t3.t_time_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_page cp2
    WHERE cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk
      AND cp2.cp_type = 'Standard'
)
GROUP BY d1.d_year, d1.d_month_seq, we.web_site_id
HAVING SUM(cs.cs_net_paid) > 100000
ORDER BY d1.d_year DESC, total_catalog_sales DESC
LIMIT 100
