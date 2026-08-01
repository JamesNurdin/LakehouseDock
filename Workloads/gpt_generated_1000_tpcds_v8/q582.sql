WITH
  -- 1. Sample a fraction of web_sales
  sampled_ws AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
  ),

  -- 2. Aggregate per order and create an array of page keys
  ws_agg AS (
    SELECT
      ws_order_number,
      ws_bill_customer_sk,
      ws_web_site_sk,
      ws_web_page_sk,
      array_agg(ws_web_page_sk) AS page_sk_array,
      sum(ws_ext_sales_price) AS total_sales,
      sum(ws_net_profit) AS total_profit
    FROM sampled_ws
    GROUP BY ws_order_number, ws_bill_customer_sk, ws_web_site_sk, ws_web_page_sk
  ),

  -- 3. Unnest the page array so each page appears on its own row
  ws_pages AS (
    SELECT
      ws_order_number,
      ws_bill_customer_sk,
      ws_web_site_sk,
      ws_web_page_sk,
      page_sk,
      total_sales,
      total_profit
    FROM ws_agg
    CROSS JOIN UNNEST(page_sk_array) AS t(page_sk)
  ),

  -- 4. Two sub‑queries that will be combined with UNION
  site_recent AS (
    SELECT web_site_sk, web_name
    FROM web_site
    WHERE web_rec_end_date >= DATE '2000-01-01'
  ),
  site_manager AS (
    SELECT web_site_sk, web_name
    FROM web_site
    WHERE web_market_manager IN ('Edward George', 'Scott Bryant')
  ),
  site_union AS (
    SELECT * FROM site_recent
    UNION
    SELECT * FROM site_manager
  ),

  -- 5. Main data set with many joins, re‑using tables under different aliases
  main_data AS (
    SELECT
      c_bill.c_customer_sk,
      c_bill.c_first_name,
      c_bill.c_last_name,
      c_bill.c_birth_country,
      hd_cur.hd_income_band_sk,
      ws_pages.ws_order_number,
      ws_pages.total_sales,
      ws_pages.total_profit,
      wp_all.wp_type,
      site_union.web_name,
      sr.sr_return_amt_inc_tax,
      sr.sr_fee,
      lp.link_image_product
    FROM ws_pages
    -- full outer join to capture pages without sales and sales without pages
    FULL OUTER JOIN web_page wp_all
      ON ws_pages.ws_web_page_sk = wp_all.wp_web_page_sk
    INNER JOIN web_site site_union
      ON ws_pages.ws_web_site_sk = site_union.web_site_sk
    INNER JOIN customer c_bill
      ON ws_pages.ws_bill_customer_sk = c_bill.c_customer_sk
    -- reuse CUSTOMER as a shipping alias (different role)
    LEFT JOIN customer c_ship
      ON ws_pages.ws_bill_customer_sk = c_ship.c_customer_sk
    INNER JOIN household_demographics hd_cur
      ON c_bill.c_current_hdemo_sk = hd_cur.hd_demo_sk
    LEFT JOIN store_returns sr
      ON sr.sr_customer_sk = c_bill.c_customer_sk
    LEFT JOIN household_demographics hd_return
      ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
    LEFT JOIN LATERAL (
      SELECT (wp_all.wp_link_count * wp_all.wp_image_count) AS link_image_product
    ) lp ON true
    WHERE NOT EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_customer_sk = c_bill.c_customer_sk
        AND sr2.sr_return_amt_inc_tax > 500
    )
  )

SELECT
  ROW_NUMBER() OVER (ORDER BY SUM(total_sales) DESC) AS row_num,
  web_name,
  c_birth_country,
  hd_income_band_sk,
  SUM(total_sales) AS sum_sales,
  SUM(total_profit) AS sum_profit,
  SUM(sr_return_amt_inc_tax) AS sum_return_amt,
  COUNT(DISTINCT wp_type) AS distinct_page_types,
  MAX(link_image_product) AS max_link_image_product
FROM main_data
GROUP BY GROUPING SETS (
  (web_name, c_birth_country, hd_income_band_sk),
  (web_name, c_birth_country)
)
ORDER BY sum_sales DESC
LIMIT 100
