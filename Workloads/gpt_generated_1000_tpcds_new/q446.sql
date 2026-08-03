WITH
  sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),

  full_outer_sales_returns AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_warehouse_sk,
      cr.cr_order_number,
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      cr.cr_warehouse_sk,
      cs.cs_ext_sales_price,
      cr.cr_return_amount
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
  ),

  joined AS (
    SELECT
      s.s_state,
      i.i_category,
      d1.d_month_seq,
      ss.ss_ext_sales_price,
      ss.ss_ticket_number,
      i.i_item_sk,
      w.w_city,
      p.p_discount_active,
      ca.ca_county,
      d1.d_year
    FROM sampled_store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d1
      ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN full_outer_sales_returns fosr
      ON i.i_item_sk = fosr.cs_item_sk
    JOIN warehouse w
      ON w.w_warehouse_sk = COALESCE(fosr.cs_warehouse_sk, fosr.cr_warehouse_sk)
    JOIN date_dim d2
      ON fosr.cs_sold_date_sk = d2.d_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d1.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d1.d_date_sk
    WHERE
      s.s_market_manager = 'David Smith'
      AND s.s_state = 'CA'
      AND i.i_brand = 'BrandX'
      AND d1.d_year = 2001
      AND ca.ca_county = 'Maricopa County'
      AND p.p_discount_active = 'Y'
      AND w.w_city = 'Los Angeles'
  ),

  aggregated AS (
    SELECT
      s_state,
      i_category,
      d_month_seq,
      SUM(ss_ext_sales_price)      AS sum_sales,
      AVG(ss_ext_sales_price)      AS avg_sales,
      COUNT(DISTINCT ss_ticket_number) AS num_transactions
    FROM joined
    GROUP BY ROLLUP (s_state, i_category, d_month_seq)
  )
SELECT
  s_state,
  i_category,
  d_month_seq,
  sum_sales,
  avg_sales,
  num_transactions,
  ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY sum_sales DESC) AS sales_rank_state,
  ROW_NUMBER() OVER (ORDER BY sum_sales DESC)                     AS sales_rank_overall
FROM aggregated
ORDER BY sum_sales DESC
LIMIT 100
