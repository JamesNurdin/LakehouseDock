WITH
  store_name_words AS (
    SELECT s_store_sk,
           s_store_name,
           split(s_store_name, ' ') AS words
    FROM store
  ),
  store_words AS (
    SELECT s_store_sk,
           word
    FROM store_name_words
    CROSS JOIN UNNEST(words) AS t(word)
  ),
  web_site_name_words AS (
    SELECT web_site_sk,
           web_name,
           split(web_name, ' ') AS words
    FROM web_site
  ),
  web_site_words AS (
    SELECT web_site_sk,
           word
    FROM web_site_name_words
    CROSS JOIN UNNEST(words) AS t(word)
  )
SELECT
  entity_type,
  entity_name,
  year,
  total_net_profit,
  name_word
FROM (
  SELECT
    'Store' AS entity_type,
    s.s_store_name AS entity_name,
    d.d_year AS year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    w.word AS name_word
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN store_words w ON s.s_store_sk = w.s_store_sk
  WHERE ss.ss_net_profit > 0
    AND s.s_store_sk NOT IN (
      SELECT ss2.ss_store_sk
      FROM store_sales ss2
      WHERE ss2.ss_net_profit > 5000
    )
  GROUP BY s.s_store_name, d.d_year, w.word
  UNION ALL
  SELECT
    'WebSite' AS entity_type,
    wsit.web_name AS entity_name,
    d.d_year AS year,
    SUM(ws.ws_net_profit) AS total_net_profit,
    w.word AS name_word
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  JOIN web_site_words w ON wsit.web_site_sk = w.web_site_sk
  WHERE ws.ws_net_profit > 0
    AND ws.ws_web_site_sk NOT IN (
      SELECT ws2.ws_web_site_sk
      FROM web_sales ws2
      WHERE ws2.ws_net_profit > 10000
    )
  GROUP BY wsit.web_name, d.d_year, w.word
) combined
ORDER BY year DESC, total_net_profit DESC
LIMIT 100
