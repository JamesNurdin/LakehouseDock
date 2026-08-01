/*
  Goal: Provide a deep‑join analytical view of web sales for the year 2001, aggregating quantities, revenue and profit by year, web site and ship mode, while showing profit/loss flag and average site profit. The query samples web_sales, reuses date and household dimensions under different aliases, includes a full outer join to web_returns, an additional inventory join, a correlated EXISTS filter, a scalar subquery, a CASE expression, GROUP BY CUBE, and limits output to 100 rows.
*/
WITH sales_sample AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit
    FROM tpcds.web_sales ws
    TABLESAMPLE BERNOULLI (10)   -- 10 % random sample
)
SELECT
    d_sold.d_year,
    ws.ws_web_site_sk,
    ws.ws_ship_mode_sk,
    SUM(ws.ws_quantity)               AS total_quantity,
    SUM(ws.ws_net_paid)               AS total_net_paid,
    SUM(ws.ws_net_profit)             AS total_net_profit,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
    )                                 AS site_avg_profit
FROM sales_sample ws
-- sold‑date dimension (first alias)
JOIN tpcds.date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
-- ship‑date dimension (second alias)
JOIN tpcds.date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
-- billing household demographics (first alias)
JOIN tpcds.household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
-- shipping household demographics (second alias)
JOIN tpcds.household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
-- income band linked through billing household demo
JOIN tpcds.income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
-- web page information
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
-- ship mode lookup
JOIN tpcds.ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
-- web site lookup
JOIN tpcds.web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
-- call centre opened on the sold date
JOIN tpcds.call_center cc
  ON cc.cc_open_date_sk = d_sold.d_date_sk
-- full outer join to returns (order‑level)
FULL OUTER JOIN tpcds.web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
-- inventory snapshot on ship date
LEFT JOIN tpcds.inventory inv
  ON inv.inv_date_sk = d_ship.d_date_sk
WHERE EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_quantity > 0
      )
  AND d_sold.d_year = 2001
  AND wp.wp_autogen_flag = 'Y'
GROUP BY CUBE (d_sold.d_year, ws.ws_web_site_sk, ws.ws_ship_mode_sk)
ORDER BY total_net_profit DESC
LIMIT 100
