WITH wp_sample AS (
   SELECT *
   FROM web_page
   TABLESAMPLE BERNOULLI (10)
   WHERE wp_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
     AND wp_autogen_flag = 'N'
     AND wp_type = 'Home'
),

wr_agg AS (
   SELECT wr_web_page_sk,
          COUNT(*) AS returns_cnt,
          SUM(wr_return_amt) AS total_return_amt,
          AVG(wr_return_amt_inc_tax) AS avg_return_inc_tax,
          MIN(wr_return_ship_cost) AS min_ship_cost,
          MAX(wr_return_ship_cost) AS max_ship_cost
   FROM web_returns
   WHERE wr_return_quantity > 1
     AND wr_return_amt > 100
     AND wr_return_ship_cost < 2000
   GROUP BY wr_web_page_sk
),

wp_url_parts AS (
   SELECT wp_web_page_sk,
          part AS url_segment
   FROM wp_sample
   CROSS JOIN UNNEST(split(wp_url, '/')) AS t(part)
),

sub1 AS (
   SELECT wp_web_page_sk, wp_url, wp_type
   FROM wp_sample
   WHERE wp_char_count > 1000
),

sub2 AS (
   SELECT wp_web_page_sk, wp_url, wp_type
   FROM wp_sample
   WHERE wp_image_count < 5
)

SELECT
   wp.wp_web_page_sk,
   wp.wp_url,
   wp.wp_type,
   agg.returns_cnt,
   agg.total_return_amt,
   agg.avg_return_inc_tax,
   agg.min_ship_cost,
   agg.max_ship_cost,
   COUNT(DISTINCT part.url_segment) AS url_segments_cnt
FROM wp_sample wp
JOIN wr_agg agg
   ON agg.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN wp_url_parts part
   ON part.wp_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_web_page_sk IN (
   SELECT wp_web_page_sk FROM sub1
   INTERSECT
   SELECT wp_web_page_sk FROM sub2
)
GROUP BY wp.wp_web_page_sk, wp.wp_url, wp.wp_type,
         agg.returns_cnt, agg.total_return_amt,
         agg.avg_return_inc_tax, agg.min_ship_cost, agg.max_ship_cost
ORDER BY agg.total_return_amt DESC
LIMIT 100
