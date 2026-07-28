/*
Goal: Produce a deep‑join analytical view that combines store sales, store returns, catalog sales, web returns and related dimensions (date, time, item, customer address, household demographics, income band, promotion, call center and store). The query aggregates total net paid, order counts, and return amounts by store state and item category, using a CUBE grouping, filters for active promotions via a sub‑query, and limits the result to the top 100 rows.
*/
WITH ss_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_ext_sales_price
    FROM store_sales ss
),
cs_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_ext_sales_price,
        cs.cs_order_number
    FROM catalog_sales cs
),
sr_base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_ticket_number,
        sr.sr_return_amt
    FROM store_returns sr
),
wr_base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_returning_addr_sk,
        wr.wr_return_amt,
        wr.wr_order_number
    FROM web_returns wr
)
SELECT
    s.s_state,
    i_ss.i_category,
    SUM(ss.ss_net_paid)                         AS total_store_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number)         AS total_store_orders,
    SUM(cs.cs_ext_sales_price)                  AS total_catalog_sales,
    COUNT(DISTINCT cs.cs_order_number)          AS total_catalog_orders,
    AVG(sr.sr_return_amt)                       AS avg_store_return_amt,
    SUM(wr.wr_return_amt)                       AS total_web_return_amt,
    COUNT(DISTINCT wr.wr_order_number)          AS total_web_orders
FROM ss_base ss
JOIN date_dim d_ss           ON ss.ss_sold_date_sk   = d_ss.d_date_sk
JOIN time_dim t_ss           ON ss.ss_sold_time_sk   = t_ss.t_time_sk
JOIN item i_ss               ON ss.ss_item_sk        = i_ss.i_item_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk   = hd_ss.hd_demo_sk
JOIN customer_address ca_ss  ON ss.ss_addr_sk        = ca_ss.ca_address_sk
JOIN store s                 ON ss.ss_store_sk       = s.s_store_sk
JOIN promotion p_ss          ON ss.ss_promo_sk       = p_ss.p_promo_sk
-- Store returns linked to the same sale ticket
JOIN sr_base sr              ON ss.ss_ticket_number = sr.sr_ticket_number
                              AND ss.ss_item_sk      = sr.sr_item_sk
JOIN date_dim d_sr           ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr           ON sr.sr_return_time_sk    = t_sr.t_time_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk    = hd_sr.hd_demo_sk
JOIN customer_address ca_sr  ON sr.sr_addr_sk          = ca_sr.ca_address_sk
JOIN item i_sr               ON sr.sr_item_sk          = i_sr.i_item_sk
-- Catalog sales joins (using the same date_dim alias as store sales for simplicity)
JOIN cs_base cs              ON cs.cs_sold_date_sk    = d_ss.d_date_sk
JOIN time_dim t_cs           ON cs.cs_sold_time_sk    = t_cs.t_time_sk
JOIN item i_cs               ON cs.cs_item_sk         = i_cs.i_item_sk
JOIN promotion p_cs          ON cs.cs_promo_sk        = p_cs.p_promo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill   ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN call_center cc          ON cs.cs_call_center_sk  = cc.cc_call_center_sk
-- Web returns joins
JOIN wr_base wr              ON wr.wr_item_sk         = i_ss.i_item_sk
JOIN date_dim d_wr           ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr           ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer_address ca_refunded      ON wr.wr_refunded_addr_sk   = ca_refunded.ca_address_sk
-- Income band join (via household demographics used in store sales)
JOIN income_band ib          ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p_sub
    WHERE p_sub.p_promo_sk = ss.ss_promo_sk
      AND p_sub.p_discount_active = 'Y'
)
GROUP BY CUBE (s.s_state, i_ss.i_category)
HAVING SUM(ss.ss_net_paid) > 1000
ORDER BY s.s_state NULLS LAST, i_ss.i_category NULLS LAST
LIMIT 100
