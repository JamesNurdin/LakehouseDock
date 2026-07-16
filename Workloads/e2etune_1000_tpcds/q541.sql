SELECT
    wp.wp_type,
    ws.ws_sold_date_sk AS sales_date_sk,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    (SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_net_paid), 0)) AS profit_margin,
    RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM web_sales ws
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
  AND wp.wp_type IN ('home', 'product', 'search')
  AND wp.wp_url LIKE 'http%://%/store/%'
GROUP BY wp.wp_type, ws.ws_sold_date_sk
HAVING SUM(ws.ws_quantity) > 50
ORDER BY ws.ws_sold_date_sk, profit_rank
LIMIT 200
