WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_net_profit,
        ws.ws_sold_date_sk
    FROM web_sales ws
)
SELECT
    ws_site.web_site_id,
    ws_site.web_name,
    substring(ws_site.web_state FROM 1 FOR 3) AS state_prefix,
    regexp_extract(ws_site.web_mkt_class, '^(\\w+)') AS market_class_word,
    COUNT(DISTINCT sd.ws_order_number) AS order_count,
    SUM(sd.ws_net_profit) AS total_sales_profit,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    (SUM(sd.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_profit_after_returns,
    ROUND(
        (SUM(sd.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) /
        (SELECT AVG(site_total)
         FROM (
             SELECT SUM(ws2.ws_net_profit) - COALESCE(SUM(wr2.wr_net_loss),0) AS site_total
             FROM web_sales ws2
             JOIN web_site ws_site2 ON ws2.ws_web_site_sk = ws_site2.web_site_sk
             JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
             LEFT JOIN web_returns wr2 ON wr2.wr_order_number = ws2.ws_order_number
             WHERE d2.d_year = 2001
             GROUP BY ws_site2.web_site_id
         ) t) * 100,
        2
    ) AS profit_vs_avg_pct
FROM sales_data sd
JOIN web_site ws_site ON sd.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = sd.ws_order_number
WHERE d.d_year = 2001
  AND regexp_like(ws_site.web_name, '^.*Store.*$')
  AND ws_site.web_city LIKE '%County'
GROUP BY
    ws_site.web_site_id,
    ws_site.web_name,
    substring(ws_site.web_state FROM 1 FOR 3),
    regexp_extract(ws_site.web_mkt_class, '^(\\w+)')
HAVING SUM(sd.ws_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
