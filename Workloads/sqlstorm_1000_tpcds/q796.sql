WITH sales_str AS (
   SELECT
      ws.ws_order_number,
      d.d_date,
      c.c_customer_sk,
      concat_ws(' ', c.c_first_name, c.c_last_name) AS cust_name,
      i.i_item_sk,
      i.i_product_name,
      i.i_item_desc,
      i.i_brand,
      i.i_color,
      i.i_size,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_quantity * i.i_current_price AS line_revenue,
      lower(i.i_product_name) AS low_prod_name,
      replace(i.i_product_name, ' ', '_') AS underscored_name,
      regexp_replace(i.i_product_name, '[^a-zA-Z0-9]', '') AS alnum_name,
      length(i.i_product_name) AS prod_name_len,
      substring(i.i_product_name, 1, 10) AS prod_name_prefix,
      trim(both ' ' FROM i.i_product_name) AS trimmed_prod_name,
      reverse(i.i_product_name) AS reversed_prod_name,
      cardinality(split(i.i_product_name, ' ')) AS prod_word_cnt,
      regexp_count(lower(i.i_item_desc), '(?i)red') AS red_occurrences,
      strpos(lower(i.i_product_name), 'pro') AS pro_position,
      CASE WHEN i.i_product_name LIKE '%Pro%' THEN 1 ELSE 0 END AS has_pro_flag
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
   WHERE ws.ws_sold_date_sk BETWEEN (SELECT min(d_date_sk) FROM date_dim WHERE d_year = 2000) AND (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2002)
), order_agg AS (
   SELECT
      s.ws_order_number,
      min(s.d_date) AS order_date,
      any_value(s.cust_name) AS customer_name,
      sum(s.ws_quantity) AS total_qty,
      sum(s.line_revenue) AS total_revenue,
      avg(s.prod_name_len) AS avg_product_name_len,
      sum(s.red_occurrences) AS total_red_word_in_desc,
      max(s.prod_word_cnt) AS max_product_name_word_count,
      count(DISTINCT s.i_brand) AS distinct_brand_count,
      array_join(array_agg(DISTINCT s.underscored_name), ', ') AS underscored_names,
      cardinality(array_distinct(array_agg(s.i_color))) AS distinct_color_count,
      regexp_replace(array_join(array_agg(DISTINCT s.underscored_name), '|'), '_+', '-') AS normalized_order_string,
      sum(s.has_pro_flag) AS pro_flag_count,
      avg(s.pro_position) AS avg_pro_position
   FROM sales_str s
   GROUP BY s.ws_order_number
   HAVING sum(s.line_revenue) > 1000
)
SELECT
   oa.ws_order_number,
   oa.order_date,
   oa.customer_name,
   oa.total_qty,
   oa.total_revenue,
   oa.avg_product_name_len,
   oa.total_red_word_in_desc,
   oa.max_product_name_word_count,
   oa.distinct_brand_count,
   oa.underscored_names,
   oa.distinct_color_count,
   oa.normalized_order_string,
   oa.pro_flag_count,
   oa.avg_pro_position,
   row_number() OVER (ORDER BY oa.total_revenue DESC) AS revenue_rank
FROM order_agg oa
ORDER BY revenue_rank
LIMIT 100
