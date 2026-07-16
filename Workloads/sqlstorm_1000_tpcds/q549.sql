WITH processed_sales AS (
   SELECT
      'store' AS sales_channel,
      ss.ss_sold_date_sk AS sale_date_sk,
      ss.ss_ticket_number AS ticket_number,
      ss.ss_customer_sk AS customer_sk,
      ss.ss_item_sk AS item_sk,
      ss.ss_net_paid AS net_paid,
      ss.ss_net_profit AS net_profit,
      concat_ws('_', CAST(ss.ss_ticket_number AS varchar)) AS ticket_concat,
      length(concat_ws('_', CAST(ss.ss_ticket_number AS varchar))) AS ticket_concat_len,
      regexp_like(concat_ws('_', CAST(ss.ss_ticket_number AS varchar)), '^\\d+$') AS ticket_numeric,
      concat_ws(' ', CAST(ss.ss_ticket_number AS varchar)) AS sales_id_str
   FROM store_sales ss
   UNION ALL
   SELECT
      'catalog' AS sales_channel,
      cs.cs_sold_date_sk,
      cs.cs_order_number,
      cs.cs_bill_customer_sk,
      cs.cs_item_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      concat_ws('_', CAST(cs.cs_order_number AS varchar)) AS ticket_concat,
      length(concat_ws('_', CAST(cs.cs_order_number AS varchar))) AS ticket_concat_len,
      regexp_like(concat_ws('_', CAST(cs.cs_order_number AS varchar)), '^\\d+$') AS ticket_numeric,
      concat_ws(' ', CAST(cs.cs_order_number AS varchar)) AS sales_id_str
   FROM catalog_sales cs
   UNION ALL
   SELECT
      'web' AS sales_channel,
      ws.ws_sold_date_sk,
      ws.ws_order_number,
      ws.ws_bill_customer_sk,
      ws.ws_item_sk,
      ws.ws_net_paid,
      ws.ws_net_profit,
      concat_ws('_', CAST(ws.ws_order_number AS varchar)) AS ticket_concat,
      length(concat_ws('_', CAST(ws.ws_order_number AS varchar))) AS ticket_concat_len,
      regexp_like(concat_ws('_', CAST(ws.ws_order_number AS varchar)), '^\\d+$') AS ticket_numeric,
      concat_ws(' ', CAST(ws.ws_order_number AS varchar)) AS sales_id_str
   FROM web_sales ws
),
customer_strings AS (
   SELECT
      c.c_customer_sk,
      lower(concat_ws(' ', c.c_first_name, c.c_last_name)) AS full_name_lower,
      replace(c.c_email_address, '@', '_at_') AS email_escaped,
      regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
      length(c.c_email_address) AS email_len,
      cardinality(split(c.c_email_address, '@')) - 1 AS email_at_parts,
      CASE WHEN regexp_like(c.c_email_address, '@gmail\\.com$') THEN 1 ELSE 0 END AS is_gmail,
      concat_ws(', ',
        ca.ca_street_number,
        ca.ca_street_name,
        ca.ca_street_type,
        coalesce(ca.ca_suite_number, ''),
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip) AS full_address,
      length(concat_ws(', ',
        ca.ca_street_number,
        ca.ca_street_name,
        ca.ca_street_type,
        coalesce(ca.ca_suite_number, ''),
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip)) AS address_len,
      cardinality(split(ca.ca_city, ' ')) AS city_word_cnt
   FROM customer c
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_strings AS (
   SELECT
      i.i_item_sk,
      concat_ws(' ', i.i_product_name, i.i_brand, i.i_category, i.i_color, i.i_size) AS full_desc,
      lower(i.i_product_name) AS product_name_lower,
      regexp_replace(i.i_product_name, '[^a-zA-Z0-9 ]', '') AS product_name_alnum,
      length(i.i_product_name) AS product_name_len,
      cardinality(split(i.i_product_name, ' ')) AS product_name_word_cnt,
      CASE WHEN lower(i.i_color) LIKE '%red%' THEN 1 ELSE 0 END AS is_red_color,
      regexp_extract(i.i_color, '([A-Za-z]+)', 1) AS color_alpha
   FROM item i
),
date_strings AS (
   SELECT
      d.d_date_sk,
      d.d_date,
      CAST(d.d_year AS varchar) AS year_str,
      d.d_year,
      d.d_month_seq,
      d.d_day_name,
      d.d_weekend,
      d.d_holiday,
      length(d.d_day_name) AS day_name_len,
      lower(d.d_day_name) AS day_name_lower,
      regexp_like(d.d_day_name, '^S') AS day_name_starts_with_s
   FROM date_dim d
)
SELECT
   ps.sales_channel,
   ds.year_str,
   count(*) AS sales_cnt,
   sum(ps.net_paid) AS total_net_paid,
   sum(ps.net_profit) AS total_net_profit,
   avg(ps.ticket_concat_len) AS avg_ticket_len,
   sum(CASE WHEN ps.ticket_numeric THEN 1 ELSE 0 END) AS numeric_ticket_cnt,
   sum(cus.is_gmail) AS gmail_customer_cnt,
   avg(cus.email_len) AS avg_email_len,
   avg(cus.address_len) AS avg_address_len,
   sum(it.is_red_color) AS red_item_cnt,
   avg(it.product_name_len) AS avg_product_name_len,
   sum(CASE WHEN ds.day_name_starts_with_s THEN 1 ELSE 0 END) AS days_starting_S_cnt,
   max(ps.ticket_concat_len) AS max_ticket_len
FROM processed_sales ps
LEFT JOIN customer_strings cus ON ps.customer_sk = cus.c_customer_sk
LEFT JOIN item_strings it ON ps.item_sk = it.i_item_sk
LEFT JOIN date_strings ds ON ps.sale_date_sk = ds.d_date_sk
GROUP BY
   ps.sales_channel,
   ds.year_str
ORDER BY total_net_paid DESC
LIMIT 50
