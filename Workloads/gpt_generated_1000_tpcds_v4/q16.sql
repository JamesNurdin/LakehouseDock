WITH filtered_returns AS (
   SELECT
      cr.cr_returned_date_sk AS date_sk,
      cr.cr_net_loss AS net_loss,
      p.p_promo_id AS promo_id,
      NULL AS wp_url,
      NULL AS wp_type
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND regexp_like(p.p_promo_id, '^AAAA.*')
   UNION ALL
   SELECT
      wr.wr_returned_date_sk AS date_sk,
      wr.wr_net_loss AS net_loss,
      NULL AS promo_id,
      wp.wp_url AS wp_url,
      wp.wp_type AS wp_type
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2001
     AND wp.wp_url LIKE '%sale%'
)
SELECT
   COALESCE(promo_id, 'NO_PROMO') AS promo_id,
   CASE
      WHEN wp_url IS NOT NULL THEN regexp_extract(wp_url, 'https?://([^/]+)/', 1)
      ELSE NULL
   END AS domain,
   SUM(net_loss) AS total_net_loss,
   COUNT(*) AS return_count
FROM filtered_returns
GROUP BY
   COALESCE(promo_id, 'NO_PROMO'),
   CASE
      WHEN wp_url IS NOT NULL THEN regexp_extract(wp_url, 'https?://([^/]+)/', 1)
      ELSE NULL
   END
ORDER BY total_net_loss DESC
LIMIT 100
