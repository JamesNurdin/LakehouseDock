WITH refunded AS (
   SELECT wp.wp_web_page_id,
          c.c_customer_id,
          SUM(wr.wr_refunded_cash) AS total_refunded,
          CASE WHEN SUM(wr.wr_refunded_cash) > 500 THEN 'HIGH' ELSE 'LOW' END AS refund_level
   FROM web_returns wr
   RIGHT OUTER JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
   WHERE wp.wp_type = 'product'
   GROUP BY wp.wp_web_page_id, c.c_customer_id
),
return_counts AS (
   SELECT wp.wp_web_page_id,
          c.c_customer_id,
          COUNT(*) AS return_count
   FROM (SELECT * FROM web_page TABLESAMPLE BERNOULLI (10)) wp
   JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN customer c
        ON wr.wr_returning_customer_sk = c.c_customer_sk
   WHERE wp.wp_rec_end_date > DATE '2000-01-01'
   GROUP BY wp.wp_web_page_id, c.c_customer_id
),
common_keys AS (
   SELECT wp_web_page_id, c_customer_id FROM refunded
   INTERSECT
   SELECT wp_web_page_id, c_customer_id FROM return_counts
),
final AS (
   SELECT 'REFUNDED' AS source,
          f.wp_web_page_id,
          f.c_customer_id,
          f.total_refunded,
          f.refund_level,
          NULL AS return_count
   FROM refunded f
   WHERE EXISTS (
       SELECT 1 FROM common_keys ck
       WHERE ck.wp_web_page_id = f.wp_web_page_id
         AND ck.c_customer_id = f.c_customer_id
   )
   UNION ALL
   SELECT 'RETURN_COUNT' AS source,
          r.wp_web_page_id,
          r.c_customer_id,
          NULL AS total_refunded,
          NULL AS refund_level,
          r.return_count
   FROM return_counts r
   WHERE EXISTS (
       SELECT 1 FROM common_keys ck
       WHERE ck.wp_web_page_id = r.wp_web_page_id
         AND ck.c_customer_id = r.c_customer_id
   )
)
SELECT source,
       wp_web_page_id,
       c_customer_id,
       total_refunded,
       refund_level,
       return_count
FROM final
ORDER BY wp_web_page_id, c_customer_id
LIMIT 100
