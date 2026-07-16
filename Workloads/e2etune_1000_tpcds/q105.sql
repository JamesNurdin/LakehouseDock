SELECT
    s.s_store_name,
    s.s_state,
    hd.hd_income_band_sk,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_qty_sold,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_qty,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_loss,
    CASE WHEN SUM(ss.ss_quantity) = 0 THEN 0
         ELSE SUM(COALESCE(sr.sr_return_quantity, 0)) * 100.0 / SUM(ss.ss_quantity)
    END AS return_rate_pct,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets
FROM store_sales ss
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
WHERE
    hd.hd_vehicle_count >= 2
    AND hd.hd_buy_potential = '1001-5000'
    AND s.s_country = 'United States'
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
GROUP BY
    s.s_store_name,
    s.s_state,
    hd.hd_income_band_sk
HAVING
    SUM(ss.ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 10
