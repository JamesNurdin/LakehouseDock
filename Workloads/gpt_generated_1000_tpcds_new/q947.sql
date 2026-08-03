WITH
  wp_agg AS (
    SELECT
      wp_customer_sk,
      COUNT(*) AS page_cnt,
      SUM(wp_link_count) AS link_sum,
      AVG(wp_char_count) AS char_avg
    FROM web_page
    WHERE wp_rec_end_date >= DATE '1999-01-01'
      AND wp_rec_end_date <= DATE '2002-01-01'
      AND wp_link_count BETWEEN 5 AND 20
      AND wp_type = 'content'
      AND wp_autogen_flag = 'N'
    GROUP BY wp_customer_sk
  ),
  cust_addr AS (
    SELECT
      c_customer_sk,
      c_current_addr_sk,
      c_current_cdemo_sk,
      c_first_name,
      c_last_name,
      c_birth_year,
      c_preferred_cust_flag
    FROM customer
    WHERE c_birth_year BETWEEN 1950 AND 1990
      AND c_preferred_cust_flag = 'Y'
  ),
  demo_filtered AS (
    SELECT
      cd_demo_sk,
      cd_gender,
      cd_marital_status,
      cd_credit_rating,
      cd_dep_count
    FROM customer_demographics
    WHERE cd_credit_rating = 'Good'
      AND cd_marital_status IN ('M', 'S')
      AND cd_dep_count <= 3
  ),
  addr_filtered AS (
    SELECT
      ca_address_sk,
      ca_state,
      ca_country,
      ca_gmt_offset
    FROM customer_address
    WHERE ca_country = 'United States'
      AND ca_gmt_offset BETWEEN -5.00 AND 0.00
  ),
  combined AS (
    SELECT
      c.c_customer_sk,
      ca.ca_state,
      cd.cd_gender,
      SUM(wp_agg.page_cnt) AS total_pages,
      SUM(wp_agg.link_sum) AS total_links,
      AVG(wp_agg.char_avg) AS avg_char_per_page
    FROM cust_addr c
    JOIN demo_filtered cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN addr_filtered ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN wp_agg ON c.c_customer_sk = wp_agg.wp_customer_sk
    GROUP BY GROUPING SETS (
      (c.c_customer_sk, ca.ca_state, cd.cd_gender),
      (ca.ca_state, cd.cd_gender),
      (c.c_customer_sk)
    )

    UNION DISTINCT

    SELECT
      c.c_customer_sk,
      ca.ca_state,
      cd.cd_gender,
      SUM(wp_agg.page_cnt) AS total_pages,
      SUM(wp_agg.link_sum) AS total_links,
      AVG(wp_agg.char_avg) AS avg_char_per_page
    FROM cust_addr c
    JOIN demo_filtered cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN addr_filtered ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN wp_agg ON c.c_customer_sk = wp_agg.wp_customer_sk
    WHERE wp_agg.page_cnt > 2
    GROUP BY GROUPING SETS (
      (c.c_customer_sk, ca.ca_state, cd.cd_gender),
      (ca.ca_state, cd.cd_gender),
      (c.c_customer_sk)
    )
  ),
  customers_without_pages AS (
    SELECT c.c_customer_sk
    FROM cust_addr c
    EXCEPT
    SELECT wp_agg.wp_customer_sk
    FROM wp_agg
    WHERE wp_agg.page_cnt = 0
  )
SELECT
  combined.c_customer_sk,
  combined.ca_state,
  combined.cd_gender,
  combined.total_pages,
  combined.total_links,
  combined.avg_char_per_page,
  RANK() OVER (PARTITION BY combined.ca_state ORDER BY combined.total_links DESC) AS state_link_rank
FROM combined
WHERE combined.c_customer_sk NOT IN (SELECT c_customer_sk FROM customers_without_pages)
ORDER BY state_link_rank, combined.total_links DESC
LIMIT 100
