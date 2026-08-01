WITH store_returns_agg AS (
   SELECT s.s_store_name AS store_name,
          r.r_reason_desc AS reason_desc,
          SUM(sr.sr_return_amt) AS total_return_amt,
          COUNT(*) AS return_cnt,
          'store_based' AS source
   FROM store_returns sr
   INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
   INNER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   INNER JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   INNER JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE sr.sr_fee > 50
     AND hd.hd_vehicle_count > 0
     AND EXISTS (
         SELECT 1
         FROM web_page wp
         WHERE wp.wp_customer_sk = c.c_customer_sk
           AND wp.wp_char_count > 1500
     )
     AND sr.sr_return_amt > (
         SELECT AVG(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_reason_sk = r.r_reason_sk
     )
   GROUP BY s.s_store_name, r.r_reason_desc
   HAVING SUM(sr.sr_return_amt) > 1000
),
web_activity_returns_agg AS (
   SELECT s.s_store_name AS store_name,
          r.r_reason_desc AS reason_desc,
          SUM(sr.sr_return_amt) AS total_return_amt,
          COUNT(*) AS return_cnt,
          'web_activity' AS source
   FROM store_returns sr
   INNER JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   INNER JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
   INNER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   INNER JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   WHERE wp.wp_image_count > 5
     AND sr.sr_return_quantity > 1
     AND r.r_reason_desc IN (
         SELECT r2.r_reason_desc
         FROM reason r2
         WHERE r2.r_reason_desc LIKE '%damaged%'
     )
   GROUP BY s.s_store_name, r.r_reason_desc
   HAVING SUM(sr.sr_return_amt) > 500
)
SELECT combined.store_name,
       combined.reason_desc,
       combined.total_return_amt,
       combined.return_cnt,
       combined.source
FROM (
   SELECT store_name, reason_desc, total_return_amt, return_cnt, source FROM store_returns_agg
   UNION ALL
   SELECT store_name, reason_desc, total_return_amt, return_cnt, source FROM web_activity_returns_agg
) AS combined
ORDER BY combined.total_return_amt DESC
LIMIT 100
