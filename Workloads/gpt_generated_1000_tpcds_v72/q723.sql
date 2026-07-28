WITH ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_web_page_sk,
        ws.ws_item_sk
    FROM web_sales ws
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    JOIN income_band ib_ship ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
)
SELECT
    r_wr.r_reason_desc,
    hd_bill.hd_buy_potential,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count,
    CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    (
        SELECT AVG(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_reason_sk = r_wr.r_reason_sk
    ) AS avg_return_amt_by_reason
FROM web_sales ws
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN income_band ib_bill
    ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN income_band ib_ship
    ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN household_demographics hd_refund
    ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN web_page wp2
    ON wr.wr_web_page_sk = wp2.wp_web_page_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_hdemo_sk = ws.ws_bill_hdemo_sk
      AND sr.sr_reason_sk = r_wr.r_reason_sk
)
GROUP BY
    r_wr.r_reason_desc,
    hd_bill.hd_buy_potential,
    r_wr.r_reason_sk
HAVING SUM(ws.ws_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
