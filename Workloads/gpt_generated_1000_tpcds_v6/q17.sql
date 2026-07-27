WITH base1 AS (
   SELECT
       wp.wp_web_page_sk,
       wp.wp_type,
       wp.wp_url,
       SUM(wr.wr_return_amt) AS total_return_amt,
       COUNT(*) AS returns_cnt,
       (SELECT MAX(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_web_page_sk = wp.wp_web_page_sk) AS max_return_amt
   FROM web_returns wr
   JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_autogen_flag = 'Y'
     AND wr.wr_return_quantity > 30
     AND EXISTS (
         SELECT 1 FROM web_returns wr3
         WHERE wr3.wr_web_page_sk = wp.wp_web_page_sk
           AND wr3.wr_refunded_cash > 200
     )
   GROUP BY wp.wp_web_page_sk, wp.wp_type, wp.wp_url
   HAVING SUM(wr.wr_return_amt) > 1000
),
base2 AS (
   SELECT
       wp.wp_web_page_sk,
       wp.wp_type,
       wp.wp_url,
       SUM(wr.wr_return_amt) AS total_return_amt,
       COUNT(*) AS returns_cnt,
       (SELECT MAX(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_web_page_sk = wp.wp_web_page_sk) AS max_return_amt
   FROM web_returns wr
   JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_autogen_flag = 'N'
     AND wp.wp_max_ad_count >= 2
     AND wr.wr_return_quantity BETWEEN 10 AND 20
   GROUP BY wp.wp_web_page_sk, wp.wp_type, wp.wp_url
   HAVING COUNT(*) >= 5
)
SELECT wp_type, wp_url, total_return_amt, returns_cnt, max_return_amt
FROM base1
UNION ALL
SELECT wp_type, wp_url, total_return_amt, returns_cnt, max_return_amt
FROM base2
ORDER BY total_return_amt DESC
LIMIT 100
