WITH filtered_promos AS (
   SELECT
      p.p_promo_sk,
      p.p_promo_name,
      substr(p.p_promo_name, 1, 10) AS promo_name_prefix,
      regexp_extract(p.p_channel_details, '(\\w+)', 1) AS first_word_channel_details,
      p.p_channel_details,
      p.p_channel_email
   FROM tpcds.promotion p
   WHERE regexp_like(p.p_channel_details, '(?i)offences')
     AND p.p_channel_email = 'Y'
     AND p.p_promo_name LIKE 'PROMO%'
)
SELECT
   fp.p_promo_sk,
   fp.promo_name_prefix,
   fp.first_word_channel_details,
   COUNT(ss.ss_ticket_number) AS sales_count,
   SUM(ss.ss_net_paid) AS total_net_paid,
   AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
   SUM(CASE WHEN ss.ss_coupon_amt > 0 THEN 1 ELSE 0 END) AS coupon_sales
FROM filtered_promos fp
JOIN tpcds.store_sales ss
   ON ss.ss_promo_sk = fp.p_promo_sk
WHERE ss.ss_coupon_amt > 0
GROUP BY
   fp.p_promo_sk,
   fp.promo_name_prefix,
   fp.first_word_channel_details
ORDER BY total_net_paid DESC
LIMIT 100
