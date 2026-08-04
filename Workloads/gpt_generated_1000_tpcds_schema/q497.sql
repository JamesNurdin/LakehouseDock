WITH
  sample_ws AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
  ),
  joined AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_sales_price,
      ws.ws_web_site_sk,
      ws.ws_promo_sk,
      c.c_customer_id,
      ca.ca_state,
      p.p_promo_name,
      p.p_purpose,
      wp.wp_max_ad_count
    FROM sample_ws ws
    INNER JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    INNER JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site s
      ON ws.ws_web_site_sk = s.web_site_sk
    WHERE s.web_rec_end_date > DATE '2000-01-01'
      AND wp.wp_max_ad_count >= 2
      AND p.p_channel_catalog = 'N'
      AND ca.ca_state = 'TX'
      AND ws.ws_sales_price > 50
      AND p.p_purpose = 'Unknown'
  ),
  agg AS (
    SELECT
      s.web_name,
      p.p_promo_name,
      SUM(j.ws_ext_sales_price) AS total_sales,
      COUNT(j.ws_order_number) AS order_cnt
    FROM joined j
    INNER JOIN web_site s
      ON j.ws_web_site_sk = s.web_site_sk
    INNER JOIN promotion p
      ON j.ws_promo_sk = p.p_promo_sk
    GROUP BY ROLLUP (s.web_name, p.p_promo_name)
  )
SELECT
  agg.web_name,
  agg.p_promo_name,
  agg.total_sales,
  agg.order_cnt,
  ROW_NUMBER() OVER (PARTITION BY agg.web_name ORDER BY agg.total_sales DESC) AS sales_rank,
  CASE WHEN agg.total_sales > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
  (
    SELECT COUNT(*) FROM (
      SELECT c1.c_customer_id
      FROM customer c1
      WHERE c1.c_preferred_cust_flag = 'Y'
      EXCEPT
      SELECT c2.c_customer_id
      FROM customer c2
      WHERE c2.c_birth_year < 1950
    ) AS diff
  ) AS diff_preferred_not_old,
  (
    SELECT COUNT(*) FROM (
      SELECT p1.p_promo_id
      FROM promotion p1
      WHERE p1.p_channel_catalog = 'N'
      INTERSECT
      SELECT p2.p_promo_id
      FROM promotion p2
      WHERE p2.p_discount_active = 'Y'
    ) AS inter
  ) AS intersect_active_catalog_promo
FROM agg
ORDER BY agg.total_sales DESC
LIMIT 100
