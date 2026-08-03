WITH filtered_returns AS (
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_store_sk,
    sr.sr_item_sk,
    sr.sr_return_amt,
    sr.sr_net_loss,
    sr.sr_reason_sk,
    c.c_email_address,
    regexp_extract(c.c_email_address, '@(.*)$', 1) AS email_domain,
    d.d_year,
    d.d_month_seq
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE regexp_like(c.c_email_address, '@example\\.com$')
)
SELECT
  concat(s.s_store_name, ' - ', s.s_city) AS store_full_name,
  fr.d_year,
  fr.d_month_seq,
  fr.email_domain,
  SUM(fr.sr_return_amt) AS total_return_amt,
  SUM(fr.sr_net_loss) AS total_net_loss,
  COUNT(*) AS return_cnt
FROM filtered_returns fr
JOIN store s ON fr.sr_store_sk = s.s_store_sk
JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%damaged%'
  AND EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_store_sk = fr.sr_store_sk
      AND ss.ss_item_sk = fr.sr_item_sk
      AND ss.ss_sold_date_sk = fr.sr_returned_date_sk
  )
GROUP BY
  concat(s.s_store_name, ' - ', s.s_city),
  fr.d_year,
  fr.d_month_seq,
  fr.email_domain
ORDER BY total_return_amt DESC
LIMIT 100
