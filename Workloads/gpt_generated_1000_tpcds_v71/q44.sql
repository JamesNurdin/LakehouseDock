SELECT DISTINCT s.s_store_id,
                s.s_store_name,
                ss.ss_net_paid
FROM   store AS s
JOIN   store_sales AS ss
       ON ss.ss_store_sk = s.s_store_sk
WHERE  s.s_rec_end_date = DATE '2000-03-12'
  AND  ss.ss_ext_tax > 20.00
LIMIT 100
