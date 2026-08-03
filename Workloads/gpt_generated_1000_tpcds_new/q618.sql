WITH
store_agg AS (
  SELECT sr_customer_sk,
         sr_returned_date_sk,
         SUM(sr_net_loss) AS store_loss,
         COUNT(*) AS store_cnt
  FROM store_returns
  WHERE sr_return_amt > 150
  GROUP BY sr_customer_sk, sr_returned_date_sk
),
web_agg AS (
  SELECT wr_refunded_customer_sk AS cust_sk,
         wr_returned_date_sk AS date_sk,
         SUM(wr_net_loss) AS web_loss,
         COUNT(*) AS web_cnt
  FROM web_returns
  WHERE wr_return_amt > 150
  GROUP BY wr_refunded_customer_sk, wr_returned_date_sk
),
union_set AS (
  SELECT sr_customer_sk AS cust_sk, sr_returned_date_sk AS date_sk FROM store_agg
  UNION
  SELECT cust_sk, date_sk FROM web_agg
),
high_loss_intersect AS (
  SELECT sr_customer_sk AS cust_sk, sr_returned_date_sk AS date_sk
  FROM store_agg
  WHERE store_loss > 500
  INTERSECT
  SELECT cust_sk, date_sk
  FROM web_agg
  WHERE web_loss > 500
),
large_web_set AS (
  SELECT cust_sk, date_sk FROM web_agg WHERE web_loss > 1000
),
final_set AS (
  SELECT cust_sk, date_sk
  FROM high_loss_intersect
  EXCEPT
  SELECT cust_sk, date_sk FROM large_web_set
)
SELECT
  f.cust_sk,
  f.date_sk,
  cc.cc_name,
  wp.wp_url,
  avg_sub.avg_loss,
  lm.loss_type,
  lm.loss_amount
FROM final_set f
JOIN store_agg sa
  ON f.cust_sk = sa.sr_customer_sk
 AND f.date_sk = sa.sr_returned_date_sk
JOIN web_agg wa
  ON f.cust_sk = wa.cust_sk
 AND f.date_sk = wa.date_sk
JOIN customer c
  ON f.cust_sk = c.c_customer_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = f.date_sk
JOIN date_dim d
  ON d.d_date_sk = f.date_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
CROSS JOIN LATERAL (
   SELECT (sa.store_loss + wa.web_loss) / 2.0 AS avg_loss
) avg_sub
CROSS JOIN LATERAL (
   SELECT map(ARRAY['store','web'], ARRAY[sa.store_loss, wa.web_loss]) AS loss_map
) map_sub
CROSS JOIN UNNEST(map_sub.loss_map) AS lm(loss_type, loss_amount)
WHERE cc.cc_state = 'CA'
  AND c.c_birth_country = 'United States'
  AND d.d_year = 2001
  AND wp.wp_type = 'content'
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND EXISTS (
        SELECT 1
        FROM call_center cc2
        WHERE cc2.cc_company = 2
          AND cc2.cc_open_date_sk = f.date_sk
      )
ORDER BY avg_sub.avg_loss DESC
LIMIT 100
