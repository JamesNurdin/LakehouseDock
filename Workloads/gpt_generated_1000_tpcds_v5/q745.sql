WITH filtered_sales AS (
  SELECT
    ws.ws_net_profit,
    ws.ws_bill_customer_sk,
    d.d_year,
    w.web_name,
    i.i_item_desc
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND regexp_like(i.i_item_desc, '[0-9]')
    AND w.web_name LIKE 'Web%'
    AND regexp_like(c.c_email_address, '^.*@example\\.com$')
)
SELECT
  concat(web_name, ' (', CAST(d_year AS varchar), ')') AS site_year,
  sum(ws_net_profit) AS total_profit,
  count(DISTINCT ws_bill_customer_sk) AS unique_customers,
  max(regexp_extract(i_item_desc, '^([^ ]+)', 1)) AS first_word_item_desc
FROM filtered_sales
GROUP BY web_name, d_year
ORDER BY total_profit DESC
LIMIT 100
