SELECT
    s.s_store_name,
    s.s_store_sk,
    i.i_item_id,
    i.i_item_sk,
    MAX(REGEXP_EXTRACT(i.i_product_name, '([A-Z]{3}[0-9]{2})', 1)) AS extracted_code,
    MAX(CONCAT(s.s_store_name, ' - ', i.i_product_name)) AS store_item_display,
    MAX(SUBSTRING(i.i_product_name, 1, 10)) AS product_name_prefix,
    SUM(ss.ss_net_paid) AS total_net_paid,
    (SELECT SUM(sr.sr_return_amt)
       FROM store_returns sr
      WHERE sr.sr_item_sk = i.i_item_sk
        AND sr.sr_store_sk = s.s_store_sk) AS total_return_amount
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2000
  AND i.i_product_name LIKE '%COOL%'
  AND REGEXP_LIKE(i.i_product_name, '[A-Z]{3}[0-9]{2}')
GROUP BY ROLLUP (s.s_store_name, s.s_store_sk, i.i_item_id, i.i_item_sk)
ORDER BY s.s_store_name ASC, total_net_paid DESC
LIMIT 100
