WITH sampled_pages AS (
       SELECT wp_web_page_sk,
              wp_url,
              wp_type,
              wp_char_count,
              wp_link_count,
              wp_image_count,
              wp_max_ad_count
       FROM web_page
       TABLESAMPLE BERNOULLI (10)
       WHERE wp_type = 'home'
   ),
   page_returns AS (
       SELECT wp.wp_web_page_sk,
              wp.wp_url,
              SUM(wr.wr_return_amt) AS total_return_amt,
              SUM(wr.wr_return_quantity) AS total_quantity,
              CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'high' ELSE 'low' END AS return_level
       FROM sampled_pages wp
       JOIN web_returns wr
         ON wr.wr_web_page_sk = wp.wp_web_page_sk
       WHERE wr.wr_return_amt > 0
       GROUP BY wp.wp_web_page_sk, wp.wp_url
   ),
   expanded_page_returns AS (
       SELECT pr.wp_web_page_sk,
              pr.wp_url,
              pr.return_level,
              t.metric_type,
              t.metric_value
       FROM page_returns pr
       CROSS JOIN UNNEST(
               ARRAY[
                   ROW('amt', pr.total_return_amt),
                   ROW('qty', pr.total_quantity)
               ]
           ) AS t(metric_type, metric_value)
   ),
   intersected_pages AS (
       SELECT wp_web_page_sk
       FROM expanded_page_returns
       WHERE metric_type = 'amt' AND metric_value > 500
       INTERSECT
       SELECT wp_web_page_sk
       FROM expanded_page_returns
       WHERE metric_type = 'qty' AND metric_value > 10
   )
SELECT wp.wp_web_page_sk,
       wp.wp_url,
       ep.return_level,
       ep.metric_type,
       ep.metric_value
FROM intersected_pages ip
JOIN web_page wp
  ON wp.wp_web_page_sk = ip.wp_web_page_sk
JOIN expanded_page_returns ep
  ON ep.wp_web_page_sk = wp.wp_web_page_sk
WHERE ep.metric_type = 'amt'
ORDER BY ep.metric_value DESC
LIMIT 100
