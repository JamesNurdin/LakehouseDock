SELECT
  cc.cc_call_center_id,
  cc.cc_name,
  concat(cc.cc_name, ' (', cc.cc_city, ')') AS call_center_full,
  regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word_desc,
  sum(cs.cs_net_profit) AS total_net_profit,
  count(*) AS sales_transactions
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_item_desc LIKE '%blue%'
  AND regexp_like(i.i_item_desc, '^[A-Za-z]+\s+[A-Za-z]+')
GROUP BY
  cc.cc_call_center_id,
  cc.cc_name,
  cc.cc_city,
  regexp_extract(i.i_item_desc, '^([^ ]+)', 1)
ORDER BY total_net_profit DESC
LIMIT 10
