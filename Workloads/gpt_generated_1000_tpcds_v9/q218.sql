WITH item_word_stats AS (
    SELECT i.i_item_sk,
           COUNT(DISTINCT w) AS distinct_word_cnt
    FROM item i
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(w)
    GROUP BY i.i_item_sk
),
web_sales_filtered AS (
    SELECT ws.ws_web_site_sk,
           ws.ws_item_sk,
           SUM(ws.ws_net_profit) AS total_profit,
           AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND wp.wp_url LIKE '%product%'
      AND regexp_like(wp.wp_url, '^https?://')
    GROUP BY ws.ws_web_site_sk, ws.ws_item_sk
)
SELECT ws.web_site_id,
       ws.web_name,
       i.i_item_id,
       i.i_brand,
       i.i_item_desc,
       pw.distinct_word_cnt,
       wsf.total_profit,
       wsf.avg_quantity,
       concat(i.i_item_id, '-', i.i_brand) AS item_key,
       regexp_extract(i.i_item_desc, '([A-Z]{2,})', 1) AS extracted_code,
       substr(i.i_item_desc, 1, 10) AS desc_prefix
FROM web_sales_filtered wsf
JOIN web_site ws ON wsf.ws_web_site_sk = ws.web_site_sk
JOIN item i ON wsf.ws_item_sk = i.i_item_sk
LEFT JOIN item_word_stats pw ON i.i_item_sk = pw.i_item_sk
WHERE ws.web_name LIKE '%Online%'
  AND regexp_like(i.i_item_desc, '(?i)glass')
ORDER BY wsf.total_profit DESC
LIMIT 100
