WITH ws_enriched AS (
  SELECT
    ws.ws_web_site_sk,
    ws.ws_net_profit,
    ws.ws_bill_customer_sk,
    i.i_item_desc,
    wp.wp_url,
    w.web_country,
    w.web_manager
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE regexp_like(i.i_item_desc, '(Portable|Wireless)')
    AND wp.wp_url LIKE 'http%://%example.com%'
    AND regexp_like(w.web_manager, 'Wilson')
)
SELECT
  ws_enriched.web_country,
  regexp_extract(ws_enriched.wp_url, 'https?://([^/]+)/', 1) AS domain,
  sum(ws_enriched.ws_net_profit) AS total_profit,
  count(distinct ws_enriched.ws_bill_customer_sk) AS unique_customers,
  min(concat(c.c_first_name, ' ', c.c_last_name)) AS sample_customer_name
FROM ws_enriched
JOIN customer c ON ws_enriched.ws_bill_customer_sk = c.c_customer_sk
GROUP BY ws_enriched.web_country,
         regexp_extract(ws_enriched.wp_url, 'https?://([^/]+)/', 1)
ORDER BY total_profit DESC
LIMIT 100
