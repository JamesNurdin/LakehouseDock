WITH
  base AS (
    SELECT
      ss.ss_sold_date_sk,
      c.c_customer_id,
      ca1.ca_state AS sales_state,
      hd1.hd_vehicle_count,
      ib1.ib_upper_bound,
      ss.ss_ext_sales_price,
      wp.wp_url,
      url_part
    FROM store_sales ss
    JOIN customer c                                 ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd1                ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN customer_address ca1                       ON ss.ss_addr_sk = ca1.ca_address_sk
    JOIN income_band ib1                            ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
    JOIN web_page wp                                ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN UNNEST(split(wp.wp_url, '/')) AS t(url_part) ON TRUE
    FULL OUTER JOIN store_sales ss_full            ON ss_full.ss_addr_sk = ca1.ca_address_sk
    JOIN household_demographics hd2                ON c.c_current_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2                            ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE ib1.ib_upper_bound > 50000
      AND c.c_birth_month = 5
  ),
  alt AS (
    SELECT
      ss2.ss_sold_date_sk,
      c2.c_customer_id,
      ca3.ca_state AS sales_state,
      hd3.hd_vehicle_count,
      ib3.ib_upper_bound,
      ss2.ss_ext_sales_price,
      wp2.wp_url,
      url_part2
    FROM store_sales ss2
    JOIN customer c2                                 ON ss2.ss_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd3                ON ss2.ss_hdemo_sk = hd3.hd_demo_sk
    JOIN customer_address ca3                       ON ss2.ss_addr_sk = ca3.ca_address_sk
    JOIN income_band ib3                            ON hd3.hd_income_band_sk = ib3.ib_income_band_sk
    JOIN web_page wp2                               ON wp2.wp_customer_sk = c2.c_customer_sk
    LEFT JOIN UNNEST(split(wp2.wp_url, '/')) AS u(url_part2) ON TRUE
    WHERE ib3.ib_upper_bound BETWEEN 50000 AND 150000
      AND c2.c_salutation = 'Mr.'
  ),
  unioned AS (
    SELECT sales_state, c_customer_id, ss_ext_sales_price, hd_vehicle_count, ib_upper_bound FROM base
    UNION DISTINCT
    SELECT sales_state, c_customer_id, ss_ext_sales_price, hd_vehicle_count, ib_upper_bound FROM alt
  ),
  excluded AS (
    SELECT sales_state, c_customer_id, ss_ext_sales_price, hd_vehicle_count, ib_upper_bound
    FROM base
    WHERE sales_state IS NULL
  ),
  final_set AS (
    SELECT * FROM unioned
    EXCEPT
    SELECT * FROM excluded
  )
SELECT
  sales_state,
  COUNT(DISTINCT c_customer_id)   AS unique_customers,
  SUM(ss_ext_sales_price)        AS total_sales,
  AVG(hd_vehicle_count)          AS avg_vehicles,
  MAX(ib_upper_bound)            AS max_income_upper
FROM final_set
GROUP BY sales_state
ORDER BY total_sales DESC
LIMIT 100
