WITH sales AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_net_profit,
    d.d_year,
    s.s_store_name,
    c.c_customer_id,
    lower(c.c_email_address) AS email_lower,
    regexp_extract(lower(c.c_email_address), '@(.+)$', 1) AS email_domain,
    trim(concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type,
                  ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip)) AS raw_address,
    regexp_replace(trim(concat_ws(' ', ca.ca_street_number, ca.ca_street_name,
                  ca.ca_street_type, ca.ca_suite_number, ca.ca_city, ca.ca_state,
                  ca.ca_zip)), '[^A-Za-z0-9 ]', '') AS normalized_address,
    i.i_product_name,
    lower(i.i_product_name) AS product_name_lower,
    replace(i.i_color, ' ', '_') AS color_underscored,
    split(regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]+', ' '), ' ') AS desc_words,
    cardinality(split(regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]+', ' '), ' ')) AS word_count,
    concat_ws(' ', i.i_product_name, s.s_store_name,
              c.c_first_name, c.c_last_name) AS combined_search_text
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year IS NOT NULL
),
agg AS (
  SELECT
    d_year,
    s_store_name,
    count(DISTINCT ss_ticket_number) AS num_orders,
    sum(ss_net_profit) AS total_profit,
    avg(ss_net_profit) AS avg_profit_per_order
  FROM sales
  GROUP BY d_year, s_store_name
),
customer_profit AS (
  SELECT
    d_year,
    s_store_name,
    c_customer_id,
    email_domain,
    sum(ss_net_profit) AS profit
  FROM sales
  GROUP BY d_year, s_store_name, c_customer_id, email_domain
),
ranked_customers AS (
  SELECT
    d_year,
    s_store_name,
    c_customer_id,
    email_domain,
    profit,
    row_number() OVER (PARTITION BY d_year, s_store_name ORDER BY profit DESC) AS rn
  FROM customer_profit
),
top_customers AS (
  SELECT
    d_year,
    s_store_name,
    array_join(
      array_agg(
        concat_ws('|', CAST(c_customer_id AS VARCHAR), email_domain, CAST(profit AS VARCHAR))
        ORDER BY profit DESC
      ),
      ','
    ) AS top_customers_concat
  FROM ranked_customers
  WHERE rn <= 10
  GROUP BY d_year, s_store_name
)
SELECT
  a.d_year,
  a.s_store_name,
  a.num_orders,
  a.total_profit,
  a.avg_profit_per_order,
  tc.top_customers_concat
FROM agg a
JOIN top_customers tc
  ON a.d_year = tc.d_year AND a.s_store_name = tc.s_store_name
