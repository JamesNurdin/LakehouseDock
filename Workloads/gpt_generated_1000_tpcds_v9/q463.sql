WITH RECURSIVE time_series(t_time_sk) AS (
    -- Anchor: the earliest time slot for hour 12
    SELECT t_time_sk
    FROM time_dim
    WHERE t_hour = 12
      AND t_time_sk = (SELECT MIN(t_time_sk) FROM time_dim WHERE t_hour = 12)
    UNION ALL
    -- Recursive step: next time key (increment by 1) while staying in hour 12
    SELECT td.t_time_sk
    FROM time_dim td
    JOIN time_series ts ON td.t_time_sk = ts.t_time_sk + 1
    WHERE td.t_hour = 12
      AND td.t_time_sk <= (SELECT MAX(t_time_sk) FROM time_dim WHERE t_hour = 12)
)
SELECT
    s.s_store_name,
    s.s_state,
    ws_site.web_name,
    i.i_category,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ss.ss_net_profit + ws.ws_net_profit) AS total_combined_net_profit,
    SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_return_quantity ELSE 0 END) AS total_return_quantity,
    (SELECT SUM(ss2.ss_ext_sales_price)
     FROM store_sales ss2
     JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
     WHERE i2.i_category = 'Electronics') AS total_electronics_sales,
    AVG(ws.ws_sales_price) AS avg_web_sales_price
FROM time_series ts
JOIN store_sales ss ON ss.ss_sold_time_sk = ts.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_return_time_sk = ts.t_time_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = ts.t_time_sk
   AND ws.ws_item_sk = i.i_item_sk
JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    i.i_category = 'Electronics'
    AND s.s_state = 'CA'
    AND ws_site.web_company_id = 3
GROUP BY
    s.s_store_name,
    s.s_state,
    ws_site.web_name,
    i.i_category
ORDER BY
    total_combined_net_profit DESC
LIMIT 100
