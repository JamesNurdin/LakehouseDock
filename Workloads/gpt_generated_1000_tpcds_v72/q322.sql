WITH cs_summary AS (
    SELECT
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        cs.cs_sold_time_sk AS time_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    GROUP BY cs.cs_bill_hdemo_sk, cs.cs_sold_time_sk
)
SELECT
    hd_final.hd_buy_potential,
    t_ws_sold.t_hour,
    SUM(cs_sum.total_sales) AS sum_sales,
    SUM(cs_sum.total_profit) AS sum_profit,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    SUM(sr.sr_return_amt_inc_tax) AS return_amount
FROM cs_summary cs_sum
JOIN household_demographics hd_final
    ON cs_sum.hd_demo_sk = hd_final.hd_demo_sk
JOIN web_sales ws
    ON ws.ws_bill_hdemo_sk = cs_sum.hd_demo_sk
JOIN time_dim t_ws_sold
    ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN household_demographics hd_ws_ship
    ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
LEFT JOIN store_returns sr
    ON sr.sr_hdemo_sk = cs_sum.hd_demo_sk
JOIN time_dim t_sr_return
    ON sr.sr_return_time_sk = t_sr_return.t_time_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_hdemo_sk = cs_sum.hd_demo_sk
      AND sr2.sr_net_loss > 100
)
GROUP BY GROUPING SETS (
    (hd_final.hd_buy_potential, t_ws_sold.t_hour),
    (hd_final.hd_buy_potential),
    ()
)
ORDER BY hd_final.hd_buy_potential, t_ws_sold.t_hour
