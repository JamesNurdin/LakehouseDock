/*
  Goal: Analyze net contribution per store and promotion, broken down by customer income band, while accounting for sales, returns and catalog returns.
  The query joins all 11 selected tables, re‑uses household_demographics and customer_address under different aliases, and includes a LEFT OUTER JOIN to preserve sales rows that have no matching store return.
*/
SELECT
    s.s_store_name,
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT ss.ss_ticket_number)               AS num_sales,
    SUM(ss.ss_net_paid)                               AS total_net_paid,
    COALESCE(SUM(sr.sr_net_loss), 0)                  AS total_return_loss,
    SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_contribution,
    COUNT(DISTINCT c.c_customer_id)                  AS unique_customers
FROM
    tpcds.store_sales ss
INNER JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
INNER JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
INNER JOIN tpcds.household_demographics hd1
    ON ss.ss_hdemo_sk = hd1.hd_demo_sk
INNER JOIN tpcds.income_band ib
    ON hd1.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN tpcds.customer_address ca1
    ON ss.ss_addr_sk = ca1.ca_address_sk
INNER JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_store_sk = s.s_store_sk
INNER JOIN tpcds.catalog_returns cr
    ON cr.cr_returning_customer_sk = c.c_customer_sk
   AND cr.cr_returning_hdemo_sk = hd1.hd_demo_sk
   AND cr.cr_returning_addr_sk = ca1.ca_address_sk
INNER JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN tpcds.ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
/* Re‑use household_demographics for the refunded side */
INNER JOIN tpcds.household_demographics hd2
    ON cr.cr_refunded_hdemo_sk = hd2.hd_demo_sk
/* Re‑use customer_address for the refunded side */
INNER JOIN tpcds.customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
GROUP BY
    s.s_store_name,
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY
    total_net_paid DESC
LIMIT 100
