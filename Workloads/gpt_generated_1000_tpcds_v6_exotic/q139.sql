WITH sales_filtered AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ext_tax,
        ss.ss_coupon_amt,
        ss.ss_quantity
    FROM store_sales ss
    WHERE ss.ss_ext_sales_price > 100.00
      AND ss.ss_quantity BETWEEN 1 AND 5
),
returns_filtered AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_hdemo_sk,
        sr.sr_refunded_cash,
        sr.sr_store_credit,
        sr.sr_net_loss,
        sr.sr_reason_sk
    FROM store_returns sr
    WHERE sr.sr_refunded_cash > 50.00
)
SELECT
    cc.cc_name,
    d_sales.d_year,
    i.i_category,
    ib.ib_upper_bound,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(sf.ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(rf.sr_refunded_cash, 0)) AS total_refunds,
    SUM(sf.ss_net_profit) - SUM(COALESCE(rf.sr_net_loss, 0)) AS net_contribution,
    AVG(CASE WHEN sf.ss_coupon_amt > 200 THEN sf.ss_coupon_amt END) AS avg_high_coupon,
    MAX(sf.ss_ext_tax) AS max_tax,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2 WHERE ib2.ib_lower_bound > 50000) AS max_upper_bound_high_income
FROM sales_filtered sf
JOIN store_sales ss
    ON sf.ss_ticket_number = ss.ss_ticket_number
JOIN returns_filtered rf
    ON rf.sr_ticket_number = sf.ss_ticket_number
JOIN date_dim d_sales
    ON sf.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
    ON sf.ss_sold_time_sk = t_sales.t_time_sk
JOIN item i
    ON sf.ss_item_sk = i.i_item_sk
JOIN customer c
    ON sf.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON sf.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sales.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN reason r
    ON rf.sr_reason_sk = r.r_reason_sk
WHERE d_sales.d_year = 2001
  AND i.i_current_price BETWEEN 20 AND 200
  AND ib.ib_upper_bound <= 130000
  AND cc.cc_state = 'CA'
  AND t_sales.t_hour BETWEEN 9 AND 17
  AND r.r_reason_desc IN ('Damaged', 'Defective')
GROUP BY
    cc.cc_name,
    d_sales.d_year,
    i.i_category,
    ib.ib_upper_bound
ORDER BY total_sales DESC
LIMIT 100
