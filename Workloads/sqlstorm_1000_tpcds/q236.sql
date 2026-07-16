WITH purchases AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_net_paid,
    c.c_email_address,
    i.i_item_desc,
    i.i_product_name,
    s.s_store_name,
    s.s_city,
    s.s_country,
    d.d_year,
    regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
    length(i.i_item_desc) AS item_desc_len,
    reverse(i.i_product_name) AS rev_product_name
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
),
url_data AS (
  SELECT
    wp.wp_url,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/?', 1) AS url_domain,
    length(wp.wp_url) AS url_len,
    replace(wp.wp_url, 'http://', '') AS url_without_proto
  FROM web_page wp
),
customer_stats AS (
  SELECT
    p.s_store_name,
    p.s_city,
    p.s_country,
    p.email_domain,
    count(*) AS purchases_cnt,
    sum(p.ss_net_paid) AS total_net_paid,
    avg(p.item_desc_len) AS avg_item_desc_len,
    max(p.item_desc_len) AS max_item_desc_len,
    min(p.item_desc_len) AS min_item_desc_len,
    array_agg(DISTINCT p.rev_product_name) AS rev_product_names
  FROM purchases p
  GROUP BY p.s_store_name, p.s_city, p.s_country, p.email_domain
),
ranked_stats AS (
  SELECT
    cs.*,
    row_number() OVER (PARTITION BY cs.s_store_name ORDER BY cs.total_net_paid DESC) AS rn
  FROM customer_stats cs
)
SELECT
  rs.s_store_name,
  rs.s_city,
  rs.s_country,
  rs.email_domain,
  rs.purchases_cnt,
  rs.total_net_paid,
  rs.avg_item_desc_len,
  rs.max_item_desc_len,
  rs.min_item_desc_len,
  array_join(rs.rev_product_names, ' | ') AS rev_product_names_concat,
  u.url_domain,
  u.url_len,
  u.url_without_proto,
  length(concat_ws(' ', rs.s_store_name, rs.s_city, rs.s_country)) AS store_full_name_len
FROM ranked_stats rs
JOIN url_data u
  ON strpos(lower(u.url_without_proto), lower(rs.s_store_name)) > 0
WHERE rs.rn = 1
ORDER BY rs.total_net_paid DESC
LIMIT 20
