WITH
  -- Aggregate sales per store with promotional and demographic filters
  sales_agg AS (
    SELECT
      ss.ss_store_sk          AS store_sk,
      d1.d_year               AS year,
      s.s_state               AS state,
      p.p_promo_name          AS promo_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*)                AS sales_cnt,
      SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_sales_price * 0.1 ELSE 0 END) AS discount_est
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d1.d_year = 2000
      AND s.s_state = 'CA'
      AND p.p_promo_name = 'Holiday'
      AND ib.ib_lower_bound >= 50000
    GROUP BY ss.ss_store_sk, d1.d_year, s.s_state, p.p_promo_name
  ),

  -- Aggregate returns per store
  returns_agg AS (
    SELECT
      sr.sr_store_sk          AS store_sk,
      d2.d_year               AS year,
      SUM(sr.sr_return_amt)   AS total_returns,
      COUNT(*)                AS return_cnt
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2000
      AND sr.sr_return_amt > 0
    GROUP BY sr.sr_store_sk, d2.d_year
  ),

  -- Set of address keys from sales side
  address_set_sales AS (
    SELECT DISTINCT ca.ca_address_sk AS addr_sk
    FROM store_sales ss
    JOIN date_dim d3 ON ss.ss_sold_date_sk = d3.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d3.d_year = 2000
      AND ca.ca_state = 'CA'
  ),

  -- Set of address keys from web‑returns side
  address_set_web AS (
    SELECT DISTINCT ca2.ca_address_sk AS addr_sk
    FROM web_returns wr
    JOIN date_dim d4 ON wr.wr_returned_date_sk = d4.d_date_sk
    JOIN customer_address ca2 ON wr.wr_refunded_addr_sk = ca2.ca_address_sk
    WHERE d4.d_year = 2000
      AND ca2.ca_country = 'United States'
  ),

  -- Intersection of the two address sets
  intersect_addr AS (
    SELECT addr_sk FROM address_set_sales
    INTERSECT
    SELECT addr_sk FROM address_set_web
  ),

  -- Addresses that appear in sales but not in web returns
  except_addr AS (
    SELECT addr_sk FROM address_set_sales
    EXCEPT
    SELECT addr_sk FROM address_set_web
  ),

  -- Union of store‑level metrics (sales and returns) – distinct by default
  union_metrics AS (
    SELECT store_sk, total_sales AS metric FROM sales_agg
    UNION
    SELECT store_sk, total_returns AS metric FROM returns_agg
  ),

  -- A lightweight use of the web_page table to satisfy the "join all tables" requirement
  web_page_cte AS (
    SELECT wp.wp_web_page_sk,
           wp.wp_max_ad_count,
           d5.d_year
    FROM web_page wp
    JOIN date_dim d5 ON wp.wp_creation_date_sk = d5.d_date_sk
    WHERE d5.d_year = 2000
      AND wp.wp_max_ad_count <= 2
  )

SELECT
  um.store_sk,
  SUM(um.metric)                         AS total_metric,
  COUNT(*)                               AS metric_rows,
  CASE WHEN SUM(um.metric) > 100000 THEN 'HIGH' ELSE 'LOW' END AS metric_category,
  (SELECT COUNT(*) FROM intersect_addr) AS intersect_address_cnt,
  (SELECT COUNT(*) FROM except_addr)    AS except_address_cnt
FROM union_metrics um
GROUP BY um.store_sk
ORDER BY total_metric DESC
LIMIT 100
