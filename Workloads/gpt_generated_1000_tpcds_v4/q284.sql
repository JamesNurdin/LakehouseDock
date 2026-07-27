SELECT
    concat('Store_', cast(ss.ss_store_sk as varchar)) AS store_id,
    d.d_date,
    substring(d.d_day_name, 1, 3) AS day_abbr,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_weekend = 'Y'
  AND regexp_like(d.d_day_name, '^S.*')
  AND EXISTS (
      SELECT 1
      FROM web_page wp
      WHERE wp.wp_creation_date_sk = d.d_date_sk
        AND regexp_like(wp.wp_url, '^https?://.*\\.html$')
        AND wp.wp_char_count > 1000
  )
GROUP BY
    concat('Store_', cast(ss.ss_store_sk as varchar)),
    d.d_date,
    substring(d.d_day_name, 1, 3)
ORDER BY total_profit DESC
LIMIT 100
