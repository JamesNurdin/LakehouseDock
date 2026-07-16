SELECT
    ws.web_mkt_class,
    ws.web_state,
    COUNT(DISTINCT ss.ss_store_sk) AS num_stores,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(ss.ss_quantity) AS total_quantity,
    RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM store_sales ss
JOIN web_site ws
    ON ss.ss_sold_date_sk = ws.web_open_date_sk
WHERE ss.ss_net_profit > 0
  AND ws.web_country = 'United States'
  AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY ws.web_mkt_class, ws.web_state
HAVING COUNT(*) > 100
ORDER BY total_net_profit DESC
LIMIT 20
