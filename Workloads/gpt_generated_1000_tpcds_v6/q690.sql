WITH avg_income AS (
        SELECT AVG(ib_upper_bound) AS avg_ub
        FROM income_band
    )
SELECT
    s.s_store_name,
    s.s_division_name,
    cc.cc_name,
    r.r_reason_desc,
    SUM(ss.ss_net_profit)               AS store_net_profit,
    SUM(cs.cs_net_profit)               AS catalog_net_profit,
    (SELECT avg_ub FROM avg_income)    AS avg_income_upper_bound
FROM store s
JOIN store_sales ss
    ON s.s_store_sk = ss.ss_store_sk
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer c_bill
    ON ss.ss_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
    ON ss.ss_addr_sk = ca_bill.ca_address_sk
JOIN household_demographics hd_bill
    ON ss.ss_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib_bill
    ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN catalog_sales cs
    ON cs.cs_order_number = ss.ss_ticket_number
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib_ship
    ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN web_returns wr
    ON wr.wr_order_number = cs.cs_order_number
WHERE ss.ss_ticket_number IN (
        SELECT sr2.sr_ticket_number FROM store_returns sr2
        UNION
        SELECT cr2.cr_order_number FROM catalog_returns cr2
    )
  AND EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = ss.ss_sold_date_sk
          AND wr2.wr_reason_sk = r.r_reason_sk
    )
GROUP BY
    s.s_store_name,
    s.s_division_name,
    cc.cc_name,
    r.r_reason_desc,
    ib_bill.ib_upper_bound
ORDER BY store_net_profit DESC
LIMIT 100
