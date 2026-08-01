WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_web_page_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq = 20
)
SELECT
    concat('Domain: ', regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)) AS domain,
    wp.wp_type AS page_type,
    COUNT(DISTINCT fs.ws_order_number) AS order_count,
    SUM(fs.ws_net_paid) AS total_net_paid,
    SUM(fs.ws_net_profit) AS total_net_profit,
    AVG(fs.ws_net_paid) AS avg_net_paid
FROM filtered_sales fs
JOIN web_page wp ON fs.ws_web_page_sk = wp.wp_web_page_sk
WHERE regexp_like(wp.wp_url, '^https?://.*\\.com/.*$')
  AND wp.wp_type LIKE 'AB%'
  AND EXISTS (
      SELECT 1
      FROM web_returns wr
      JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
      WHERE wr.wr_order_number = fs.ws_order_number
        AND r.r_reason_desc LIKE '%damaged%'
  )
GROUP BY
    concat('Domain: ', regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)),
    wp.wp_type
HAVING SUM(fs.ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales) * 2
ORDER BY total_net_profit DESC
LIMIT 100
