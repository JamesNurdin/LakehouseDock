WITH item_sig AS (
  SELECT
    i_item_sk,
    lower(regexp_replace(coalesce(i_product_name, ''), '[^a-zA-Z0-9]', '')) AS clean_product_name,
    lower(regexp_replace(coalesce(i_item_desc, ''), '[^a-zA-Z0-9]', '')) AS clean_desc,
    lower(regexp_replace(coalesce(i_brand, ''), '[^a-zA-Z0-9]', '')) AS clean_brand,
    lower(regexp_replace(coalesce(i_color, ''), '[^a-zA-Z0-9]', '')) AS clean_color,
    concat_ws(' ',
      lower(regexp_replace(coalesce(i_product_name, ''), '[^a-zA-Z0-9]', '')),
      lower(regexp_replace(coalesce(i_item_desc, ''), '[^a-zA-Z0-9]', '')),
      lower(regexp_replace(coalesce(i_brand, ''), '[^a-zA-Z0-9]', '')),
      lower(regexp_replace(coalesce(i_color, ''), '[^a-zA-Z0-9]', ''))
    ) AS signature
  FROM item
),
sales_union AS (
  SELECT cs.cs_order_number AS order_number,
         cs.cs_item_sk AS item_sk,
         cs.cs_net_paid AS net_paid,
         cs.cs_sold_date_sk AS date_sk,
         cs.cs_quantity AS quantity,
         c.c_first_name,
         c.c_last_name,
         c.c_email_address
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  UNION ALL
  SELECT ss.ss_ticket_number AS order_number,
         ss.ss_item_sk AS item_sk,
         ss.ss_net_paid AS net_paid,
         ss.ss_sold_date_sk AS date_sk,
         ss.ss_quantity AS quantity,
         c.c_first_name,
         c.c_last_name,
         c.c_email_address
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  UNION ALL
  SELECT ws.ws_order_number AS order_number,
         ws.ws_item_sk AS item_sk,
         ws.ws_net_paid AS net_paid,
         ws.ws_sold_date_sk AS date_sk,
         ws.ws_quantity AS quantity,
         c.c_first_name,
         c.c_last_name,
         c.c_email_address
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
),
joined AS (
  SELECT su.order_number,
         su.net_paid,
         su.quantity,
         su.date_sk,
         su.c_first_name,
         su.c_last_name,
         su.c_email_address,
         isig.signature,
         length(isig.signature) AS sig_length,
         cardinality(split(isig.signature, ' ')) AS word_count,
         regexp_extract(isig.signature, '(gift|promo|sale)', 1) AS gift_match,
         replace(isig.signature, ' ', '_') AS signature_underscored,
         lower(regexp_replace(isig.signature, '[aeiou]', '')) AS consonant_sig,
         substr(isig.signature, 1, 10) AS signature_prefix
  FROM sales_union su
  JOIN item_sig isig ON su.item_sk = isig.i_item_sk
),
aggregated AS (
  SELECT
    signature_underscored,
    count(*) AS total_sales,
    sum(net_paid) AS total_net_paid,
    avg(sig_length) AS avg_sig_len,
    avg(word_count) AS avg_word_cnt,
    sum(CASE WHEN gift_match IS NOT NULL THEN 1 ELSE 0 END) AS sales_with_gift,
    count(DISTINCT lower(regexp_replace(c_email_address, '[^a-z0-9]', ''))) AS distinct_email_hashes,
    max(signature_prefix) AS max_sig_prefix
  FROM joined
  GROUP BY signature_underscored
)
SELECT
  signature_underscored,
  total_sales,
  total_net_paid,
  avg_sig_len,
  avg_word_cnt,
  sales_with_gift,
  distinct_email_hashes,
  max_sig_prefix
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 10
