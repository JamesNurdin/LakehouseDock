WITH filtered_sites AS (
    SELECT
        web_site_sk,
        web_name,
        regexp_extract(web_name, '(\\w+)', 1) AS first_word,
        substring(web_name, 1, 5) AS name_prefix
    FROM web_site
    WHERE regexp_like(web_name, 'Market')
      AND web_name LIKE '%Market%'
)
SELECT
    d.d_year,
    fs.first_word,
    fs.name_prefix,
    concat(fs.first_word, '-', CAST(d.d_year AS VARCHAR)) AS site_year_key,
    sum(ws.ws_net_paid) AS total_net_paid,
    sum(ws.ws_net_profit) AS total_net_profit,
    count(*) AS sales_count,
    CASE
        WHEN sum(ws.ws_net_profit) > 100000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS profit_category
FROM filtered_sites AS fs
JOIN web_sales ws
    ON ws.ws_web_site_sk = fs.web_site_sk
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
WHERE ws.ws_quantity > 1
  AND ws.ws_net_paid > 0
GROUP BY
    d.d_year,
    fs.first_word,
    fs.name_prefix,
    concat(fs.first_word, '-', CAST(d.d_year AS VARCHAR))
ORDER BY total_net_paid DESC
LIMIT 100
