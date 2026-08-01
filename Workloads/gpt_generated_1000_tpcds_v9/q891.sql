SELECT DISTINCT
    s.s_store_id,
    s.s_store_name,
    ss.ss_coupon_amt,
    ss.ss_ext_tax
FROM tpcds.store_sales AS ss
JOIN tpcds.store AS s
  ON ss.ss_store_sk = s.s_store_sk
WHERE ss.ss_coupon_amt > 500
  AND ss.ss_ext_tax > 20
ORDER BY s.s_store_id
LIMIT 100
