WITH td AS (
    SELECT *
    FROM time_dim
    WHERE t_hour = 13
      AND t_am_pm = 'PM'
      AND t_minute = 5
)
SELECT
    i.i_brand_id,
    c.c_birth_year,
    ib.ib_lower_bound,
    p.p_promo_id,
    sm.sm_type,
    r.r_reason_desc,
    SUM(cs.cs_net_paid)               AS total_cs_net_paid,
    SUM(cr.cr_net_loss)               AS total_cr_net_loss,
    SUM(ss.ss_net_profit)             AS total_ss_net_profit,
    SUM(sr.sr_net_loss)               AS total_sr_net_loss,
    SUM(ws.ws_net_paid)               AS total_ws_net_paid,
    SUM(wr.wr_net_loss)               AS total_wr_net_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt
FROM td
LEFT JOIN catalog_sales cs
       ON cs.cs_sold_time_sk = td.t_time_sk
LEFT JOIN catalog_returns cr
       ON cr.cr_returned_time_sk = td.t_time_sk
      AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN store_sales ss
       ON ss.ss_sold_time_sk = td.t_time_sk
LEFT JOIN store_returns sr
       ON sr.sr_return_time_sk = td.t_time_sk
      AND sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN web_sales ws
       ON ws.ws_sold_time_sk = td.t_time_sk
LEFT JOIN web_returns wr
       ON wr.wr_returned_time_sk = td.t_time_sk
      AND wr.wr_order_number = ws.ws_order_number
-- Dimension joins (via catalog_sales as the hub)
LEFT JOIN item i
       ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
       ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN household_demographics hd
       ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN promotion p
       ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN reason r
       ON cr.cr_reason_sk = r.r_reason_sk
WHERE i.i_brand_id = 6008007
  AND c.c_birth_year BETWEEN 1970 AND 1990
  AND ib.ib_lower_bound >= 50000
  AND r.r_reason_desc LIKE 'Lost my job%'
GROUP BY ROLLUP (i.i_brand_id, c.c_birth_year, ib.ib_lower_bound, p.p_promo_id, sm.sm_type, r.r_reason_desc)
LIMIT 100
