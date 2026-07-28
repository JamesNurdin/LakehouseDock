WITH page_return_stats AS (
   SELECT
       wp.wp_web_page_sk,
       wp.wp_url,
       wp.wp_type,
       wp.wp_autogen_flag,
       wp.wp_image_count,
       COUNT(wr.wr_return_quantity) AS return_cnt,
       SUM(wr.wr_return_amt) AS total_return_amt,
       SUM(wr.wr_return_tax) AS total_return_tax,
       AVG(wr.wr_return_quantity) AS avg_return_qty,
       CASE 
           WHEN wp.wp_image_count >= 5 THEN 'High Image'
           WHEN wp.wp_image_count >= 2 THEN 'Medium Image'
           ELSE 'Low Image'
       END AS image_category
   FROM web_page wp
   LEFT JOIN web_returns wr
       ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_autogen_flag = 'N'
     AND wp.wp_rec_end_date > DATE '2000-01-01'
     AND wp.wp_image_count >= 2
   GROUP BY
       wp.wp_web_page_sk,
       wp.wp_url,
       wp.wp_type,
       wp.wp_autogen_flag,
       wp.wp_image_count,
       CASE 
           WHEN wp.wp_image_count >= 5 THEN 'High Image'
           WHEN wp.wp_image_count >= 2 THEN 'Medium Image'
           ELSE 'Low Image'
       END
),
ranked_stats AS (
   SELECT
       prs.*,
       RANK() OVER (PARTITION BY prs.image_category ORDER BY prs.total_return_amt DESC) AS img_cat_rank,
       AVG(prs.total_return_amt) OVER (PARTITION BY prs.image_category) AS avg_return_amt_by_cat
   FROM page_return_stats prs
   WHERE prs.total_return_amt > 0
)
SELECT
   rs.wp_web_page_sk,
   rs.wp_url,
   rs.wp_type,
   rs.image_category,
   rs.return_cnt,
   rs.total_return_amt,
   rs.total_return_tax,
   rs.avg_return_qty,
   rs.img_cat_rank,
   rs.avg_return_amt_by_cat
FROM ranked_stats rs
WHERE rs.return_cnt >= 5
  AND rs.avg_return_amt_by_cat > 100
ORDER BY rs.total_return_amt DESC
LIMIT 100
