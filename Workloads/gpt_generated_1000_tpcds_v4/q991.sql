SELECT
    concat(s.s_city, ', ', s.s_state) AS location,
    s.s_store_name,
    sum(ss.ss_net_paid) AS total_net_paid,
    avg(ss.ss_ext_discount_amt) AS avg_discount,
    count(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    regexp_extract(cd.cd_credit_rating, '\\d+', 1) AS credit_rating_number
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE regexp_like(s.s_hours, '^8AM-.*$')
  AND s.s_city LIKE 'A%'
  AND regexp_extract(cd.cd_credit_rating, '\\d+', 1) IS NOT NULL
  AND ib.ib_lower_bound >= 50000
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_net_paid > 5000
    )
GROUP BY
    concat(s.s_city, ', ', s.s_state),
    s.s_store_name,
    regexp_extract(cd.cd_credit_rating, '\\d+', 1)
HAVING sum(ss.ss_net_paid) > 100000
   AND avg(ss.ss_ext_discount_amt) > 5
ORDER BY total_net_paid DESC
LIMIT 100
