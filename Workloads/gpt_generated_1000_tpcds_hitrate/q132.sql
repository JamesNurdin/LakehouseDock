WITH
  sales_agg AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_customer_sk,
      ss.ss_ticket_number,
      SUM(ss.ss_net_paid)               AS total_net_paid,
      SUM(ss.ss_net_profit)             AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_store_sk, ss.ss_customer_sk, ss.ss_ticket_number
  ),

  returns_agg AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_store_sk,
      sr.sr_customer_sk,
      sr.sr_ticket_number,
      sr.sr_reason_sk,
      SUM(sr.sr_return_amt) AS total_return_amt,
      SUM(sr.sr_net_loss)   AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk, sr.sr_store_sk, sr.sr_customer_sk, sr.sr_ticket_number, sr.sr_reason_sk
  ),

  joined AS (
    SELECT
      d.d_year,
      s.s_store_name,
      i.i_item_desc,
      c.c_customer_id,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cp.cp_catalog_page_id,
      cc.cc_call_center_id,
      wp.wp_url,
      r.r_reason_desc,
      sa.total_net_paid,
      sa.total_net_profit,
      ra.total_return_amt,
      ra.total_net_loss,
      (sa.total_net_paid - COALESCE(ra.total_return_amt, 0))                     AS net_sales_after_returns,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY (sa.total_net_paid - COALESCE(ra.total_return_amt, 0)) DESC) AS sales_rank
    FROM sales_agg sa
    JOIN returns_agg ra
      ON sa.ss_ticket_number = ra.sr_ticket_number
     AND sa.ss_item_sk      = ra.sr_item_sk
     AND sa.ss_store_sk     = ra.sr_store_sk
     AND sa.ss_customer_sk  = ra.sr_customer_sk
    JOIN date_dim d          ON sa.ss_sold_date_sk = d.d_date_sk
    JOIN store s             ON sa.ss_store_sk   = s.s_store_sk
    JOIN item i              ON sa.ss_item_sk    = i.i_item_sk
    JOIN customer c          ON sa.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp     ON d.d_date_sk = cp.cp_start_date_sk
    JOIN call_center cc      ON d.d_date_sk = cc.cc_open_date_sk
    JOIN web_page wp         ON c.c_customer_sk = wp.wp_customer_sk
    JOIN reason r            ON ra.sr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_year IN (1950, 1960, 1971)
      AND d.d_holiday = 'N'
      AND s.s_market_manager = 'John Miller'
      AND i.i_brand = 'BrandX'
      AND cc.cc_market_manager = 'Edward Stone'
      AND cp.cp_type = 'web'
  )

SELECT
  d_year,
  s_store_name,
  i_item_desc,
  c_customer_id,
  net_sales_after_returns,
  sales_rank
FROM (
  SELECT d_year, s_store_name, i_item_desc, c_customer_id, net_sales_after_returns, sales_rank
  FROM joined
  EXCEPT
  SELECT d_year, s_store_name, i_item_desc, c_customer_id, net_sales_after_returns, sales_rank
  FROM joined
  WHERE sales_rank > 10
) final_result
ORDER BY d_year DESC, net_sales_after_returns DESC
LIMIT 100
