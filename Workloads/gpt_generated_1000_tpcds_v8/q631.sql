WITH sales_store AS (
   SELECT
       s.s_store_sk,
       s.s_store_name,
       s.s_city,
       SUM(ss.ss_net_profit) AS profit,
       COUNT(*) AS sales_cnt,
       CONCAT(s.s_store_name, ' - ', s.s_city) AS store_label
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
   GROUP BY s.s_store_sk, s.s_store_name, s.s_city
   HAVING SUM(ss.ss_net_profit) > 20000
),
returns_store AS (
   SELECT
       s.s_store_sk,
       s.s_store_name,
       s.s_city,
       SUM(sr.sr_net_loss) AS loss,
       COUNT(*) AS return_cnt,
       CONCAT(s.s_store_name, ' - ', s.s_city) AS store_label
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
     AND REGEXP_LIKE(r.r_reason_desc, '(?i)damage|defect')
   GROUP BY s.s_store_sk, s.s_store_name, s.s_city
   HAVING SUM(sr.sr_net_loss) > 5000
),
union_stores AS (
   SELECT s_store_sk, store_label FROM sales_store
   UNION
   SELECT s_store_sk, store_label FROM returns_store
),
intersect_stores AS (
   SELECT s_store_sk FROM sales_store
   INTERSECT
   SELECT s_store_sk FROM returns_store
),
web_pages AS (
   SELECT
       wp.wp_web_page_sk,
       wp.wp_url,
       REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS domain
   FROM web_page wp
   WHERE wp.wp_url LIKE '%://%com%'
),
final AS (
   SELECT
       us.s_store_sk,
       us.store_label,
       ss.profit,
       rs.loss,
       lt.sub_label,
       wp.domain
   FROM union_stores us
   JOIN intersect_stores i ON us.s_store_sk = i.s_store_sk
   LEFT JOIN sales_store ss ON us.s_store_sk = ss.s_store_sk
   LEFT JOIN returns_store rs ON us.s_store_sk = rs.s_store_sk
   LEFT JOIN LATERAL (
       SELECT SUBSTRING(us.store_label FROM 1 FOR 10) AS sub_label
   ) lt ON true
   LEFT JOIN web_pages wp ON wp.wp_web_page_sk = (
       SELECT MIN(wp2.wp_web_page_sk) FROM web_pages wp2
   )
   WHERE us.store_label LIKE '%Store%'
)
SELECT
   s_store_sk,
   store_label,
   profit,
   loss,
   sub_label,
   domain
FROM final
ORDER BY profit DESC NULLS LAST, loss DESC NULLS LAST
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
