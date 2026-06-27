/*
  Net‑profit analysis for catalog sales in 2001, broken down by call‑center, ship mode,
  household income‑band and state. Returns are joined on order number and subtracted
  from the sales profit to show the adjusted net profit.
*/
WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        hd.hd_income_band_sk,
        ca.ca_state,
        d.d_year
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss,
        hd.hd_income_band_sk AS hd_income_band_sk_ret,
        ca.ca_state AS ca_state_ret,
        d.d_year AS return_year
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
)
SELECT
    s.d_year,
    cc.cc_name,
    sm.sm_type,
    s.hd_income_band_sk,
    s.ca_state,
    SUM(s.cs_net_paid)                     AS total_sales_net_paid,
    SUM(s.cs_net_profit)                   AS total_sales_net_profit,
    COALESCE(SUM(r.cr_net_loss), 0)         AS total_returns_net_loss,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.cr_net_loss), 0) AS net_profit_after_returns
FROM sales s
JOIN call_center cc
    ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
GROUP BY
    s.d_year,
    cc.cc_name,
    sm.sm_type,
    s.hd_income_band_sk,
    s.ca_state
ORDER BY
    s.d_year,
    total_sales_net_paid DESC
