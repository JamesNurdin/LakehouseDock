WITH filtered_web AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    ws.ws_bill_cdemo_sk,
    ws.ws_web_page_sk,
    ws.ws_sold_time_sk,
    wp.wp_url
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE regexp_like(wp.wp_url, 'promo.*\\.html$')
    AND wp.wp_type LIKE '%landing%'
)
SELECT
  cd.cd_gender,
  cd.cd_credit_rating,
  COUNT(DISTINCT fw.ws_order_number) AS order_count,
  SUM(fw.ws_net_profit) AS total_net_profit,
  AVG(fw.ws_net_profit) AS avg_net_profit,
  regexp_extract(fw.wp_url, 'https?://([^/]+)/', 1) AS domain,
  (
    SELECT AVG(ss.ss_net_profit)
    FROM store_sales ss
    WHERE ss.ss_cdemo_sk = cd.cd_demo_sk
  ) AS store_avg_net_profit
FROM filtered_web fw
JOIN customer_demographics cd ON fw.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN time_dim t ON fw.ws_sold_time_sk = t.t_time_sk
WHERE t.t_hour BETWEEN 9 AND 17
GROUP BY cd.cd_gender,
         cd.cd_credit_rating,
         cd.cd_demo_sk,
         regexp_extract(fw.wp_url, 'https?://([^/]+)/', 1)
HAVING SUM(fw.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
