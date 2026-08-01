WITH
  sales_agg AS (
    SELECT
      c.c_customer_sk,
      d.d_year,
      p.p_promo_id,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_channel_email = 'N'
      AND p.p_response_target > 5
      AND ss.ss_net_paid > 100
    GROUP BY c.c_customer_sk, d.d_year, p.p_promo_id
  ),
  web_agg AS (
    SELECT
      c.c_customer_sk,
      d.d_year,
      COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
      SUM(wp.wp_char_count) AS total_chars
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND wp.wp_type = 'Content'
      AND wp.wp_char_count > 1000
    GROUP BY c.c_customer_sk, d.d_year
  ),
  intersect_customers AS (
    SELECT c_customer_sk FROM sales_agg WHERE total_net_paid > 2000
    INTERSECT
    SELECT c_customer_sk FROM web_agg WHERE total_chars > 8000
  ),
  combined AS (
    SELECT
      COALESCE(sa.c_customer_sk, wa.c_customer_sk) AS customer_sk,
      COALESCE(sa.d_year, wa.d_year) AS year,
      sa.total_net_paid,
      sa.sales_cnt,
      wa.distinct_pages,
      wa.total_chars,
      sa.p_promo_id
    FROM sales_agg sa
    FULL OUTER JOIN web_agg wa
      ON sa.c_customer_sk = wa.c_customer_sk
     AND sa.d_year = wa.d_year
  )
SELECT
  c.customer_sk,
  c.year,
  c.total_net_paid,
  c.sales_cnt,
  c.distinct_pages,
  c.total_chars,
  lp.latest_promo_name,
  (SELECT COUNT(*) FROM promotion p WHERE p.p_channel_email = 'N') AS email_promo_count
FROM combined c
LEFT JOIN LATERAL (
  SELECT p.p_promo_name AS latest_promo_name
  FROM promotion p
  WHERE p.p_promo_id = c.p_promo_id
  ORDER BY p.p_start_date_sk DESC
  LIMIT 1
) lp ON TRUE
WHERE c.customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
  AND (c.total_net_paid IS NULL OR c.total_net_paid > 500)
  AND (c.distinct_pages IS NULL OR c.distinct_pages >= 1)
  AND (c.total_chars IS NULL OR c.total_chars < 20000)
ORDER BY c.year DESC, c.total_net_paid DESC
LIMIT 100
