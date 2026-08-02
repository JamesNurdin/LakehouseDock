WITH ss_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_hdemo_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
)
SELECT
    d_sales.d_date,
    ib_ss.ib_lower_bound,
    ib_ss.ib_upper_bound,
    SUM(COALESCE(ss_base.ss_net_paid, 0)) AS total_store_sales,
    SUM(COALESCE(ss_base.ss_net_profit, 0)) AS total_store_profit,
    COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS total_return_amount,
    COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
    (SELECT AVG(ib_sub.ib_upper_bound) FROM income_band ib_sub) AS avg_income_upper_bound
FROM ss_base
FULL OUTER JOIN store_returns sr
    ON sr.sr_item_sk = ss_base.ss_item_sk
   AND sr.sr_ticket_number = ss_base.ss_ticket_number
LEFT JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_sales
    ON ss_base.ss_sold_date_sk = d_sales.d_date_sk
JOIN household_demographics hd_ss
    ON ss_base.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN income_band ib_ss
    ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
   AND ws.ws_bill_hdemo_sk = hd_ss.hd_demo_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN household_demographics hd_ws_ship
    ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN income_band ib_ws_ship
    ON hd_ws_ship.hd_income_band_sk = ib_ws_ship.ib_income_band_sk
JOIN household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN income_band ib_ws_bill
    ON hd_ws_bill.hd_income_band_sk = ib_ws_bill.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_hdemo_sk = hd_ss.hd_demo_sk
      AND sr2.sr_returned_date_sk = d_sales.d_date_sk
      AND sr2.sr_reversed_charge > 500
)
  AND d_sales.d_year = 2002
GROUP BY d_sales.d_date, ib_ss.ib_lower_bound, ib_ss.ib_upper_bound
ORDER BY total_store_sales DESC
LIMIT 100
