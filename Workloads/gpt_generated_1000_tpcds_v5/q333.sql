WITH filtered_dates AS (
   SELECT d_date_sk, d_year, d_fy_week_seq
   FROM date_dim
   WHERE d_current_day = 'N'
     AND d_fy_week_seq = (
         SELECT max(d_fy_week_seq)
         FROM date_dim
         WHERE d_current_day = 'N'
     )
)
SELECT
    r.r_reason_desc,
    fd.d_year,
    wp.wp_type,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    CONCAT('URL:', wp.wp_url) AS full_url,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    AVG(sr.sr_return_amt) AS avg_return_amount
FROM store_returns sr
JOIN filtered_dates fd ON sr.sr_returned_date_sk = fd.d_date_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_page wp ON wp.wp_creation_date_sk = fd.d_date_sk
WHERE regexp_like(r.r_reason_desc, '(?i)purchase')
  AND wp.wp_url LIKE '%example.com%'
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_access_date_sk = fd.d_date_sk
          AND wp2.wp_type LIKE 'C%'
      )
GROUP BY
    r.r_reason_desc,
    fd.d_year,
    wp.wp_type,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1),
    CONCAT('URL:', wp.wp_url)
ORDER BY total_net_loss DESC
LIMIT 100
