WITH income_band_avg AS (
        SELECT hd.hd_demo_sk,
               AVG(ib.ib_upper_bound) AS avg_upper_bound
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY hd.hd_demo_sk
    ),
    avg_store_net AS (
        SELECT AVG(ss.ss_net_paid) AS avg_store_net_paid
        FROM store_sales ss
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cp.cp_department,
    s.s_store_name,
    w_cs.w_city AS warehouse_city,
    ib.ib_upper_bound,
    td_cs.t_hour AS sold_hour,
    COALESCE(cs.cs_net_paid, 0) AS catalog_net_paid,
    COALESCE(ss.ss_net_paid, 0) AS store_net_paid,
    COALESCE(ws.ws_net_paid, 0) AS web_net_paid,
    (COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_net_paid,
    (SELECT avg_store_net_paid FROM avg_store_net) AS avg_store_net_paid,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY (COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) DESC) AS profit_rank,
    CASE
        WHEN r_cr.r_reason_desc IS NOT NULL THEN r_cr.r_reason_desc
        WHEN r_sr.r_reason_desc IS NOT NULL THEN r_sr.r_reason_desc
        WHEN r_wr.r_reason_desc IS NOT NULL THEN r_wr.r_reason_desc
        ELSE 'No Return'
    END AS return_reason
FROM customer c
JOIN catalog_sales cs               ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp                ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cs                ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse w_cs                 ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN time_dim td_cs                 ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN household_demographics hd     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib                 ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca           ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_returns cr       ON cr.cr_order_number = cs.cs_order_number
                                    AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN reason r_cr              ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN ship_mode sm_cr          ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN warehouse w_cr           ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
LEFT JOIN time_dim td_cr           ON cr.cr_returned_time_sk = td_cr.t_time_sk
-- Store channel
LEFT JOIN store_sales ss           ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN time_dim td_ss           ON ss.ss_sold_time_sk = td_ss.t_time_sk
LEFT JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
LEFT JOIN customer_address ca_ss   ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN store_returns sr        ON sr.sr_ticket_number = ss.ss_ticket_number
                                    AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN reason r_sr              ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN time_dim td_sr           ON sr.sr_return_time_sk = td_sr.t_time_sk
-- Web channel
LEFT JOIN web_sales ws            ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN time_dim td_ws           ON ws.ws_sold_time_sk = td_ws.t_time_sk
LEFT JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
LEFT JOIN customer_address ca_ws   ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
LEFT JOIN web_returns wr          ON wr.wr_order_number = ws.ws_order_number
                                    AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN reason r_wr              ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN time_dim td_wr           ON wr.wr_returned_time_sk = td_wr.t_time_sk
WHERE cp.cp_department = 'Electronics'
  AND s.s_state = 'CA'
  AND w_cs.w_city = 'Seattle'
  AND ib.ib_upper_bound > 50000
  AND td_cs.t_hour BETWEEN 9 AND 17
  AND (
        r_cr.r_reason_desc LIKE '%Damaged%'
        OR r_sr.r_reason_desc LIKE '%Damaged%'
        OR r_wr.r_reason_desc LIKE '%Damaged%'
      )
ORDER BY total_net_paid DESC, profit_rank
LIMIT 100
