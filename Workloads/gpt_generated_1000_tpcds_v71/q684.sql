WITH web_returns_year AS (
    SELECT d2.d_year,
           SUM(wr.wr_return_amt) AS total_wr_amt
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    GROUP BY d2.d_year
)
SELECT
    s.s_store_id,
    s.s_state,
    d.d_year,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    COALESCE(SUM(sr.sr_net_loss), 0) AS store_returns_loss,
    COALESCE(wry.total_wr_amt, 0) AS total_web_returns_amount,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    CASE
        WHEN SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS overall_status
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN web_returns_year wry ON wry.d_year = d.d_year
WHERE d.d_year = 2002
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND ca.ca_country = 'United States'
  AND cc.cc_gmt_offset > -5.00
  AND sm.sm_type = 'AIR'
GROUP BY s.s_store_id, s.s_state, d.d_year, wry.total_wr_amt
ORDER BY store_sales_profit DESC
LIMIT 100
