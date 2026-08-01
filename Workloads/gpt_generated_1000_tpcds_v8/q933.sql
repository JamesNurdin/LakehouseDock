WITH
  customer_income AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      hd.hd_demo_sk,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      ca.ca_city,
      ca.ca_state,
      ca.ca_gmt_offset
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  ),
  sampled_items AS (
    SELECT *
    FROM item TABLESAMPLE BERNOULLI (10)   -- 10% random sample
  ),
  sales_join AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_store_sk,
      ci.c_customer_id,
      ci.ca_gmt_offset,
      i.i_item_id,
      i.i_current_price,
      s.s_store_name,
      t.t_hour,
      ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn_customer_sales
    FROM store_sales ss
    JOIN sampled_items i               ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_income ci            ON ss.ss_customer_sk = ci.c_customer_sk
    JOIN store s                        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t                    ON ss.ss_sold_time_sk = t.t_time_sk
  ),
  full_join_ws AS (
    SELECT
      COALESCE(sj.ss_ticket_number, wp.wp_web_page_sk) AS join_key,
      sj.*,                     -- all columns from sales_join
      wp.wp_url,
      wp.wp_type
    FROM sales_join sj
    FULL OUTER JOIN web_page wp
      ON sj.ss_customer_sk = wp.wp_customer_sk
  ),
  final AS (
    SELECT DISTINCT
      fj.join_key,
      fj.c_customer_id,
      fj.i_item_id,
      fj.i_current_price,
      fj.s_store_name,
      fj.t_hour,
      fj.wp_url,
      fj.wp_type,
      fj.ca_gmt_offset,
      fj.rn_customer_sales,
      ROW_NUMBER() OVER (ORDER BY fj.i_current_price DESC) AS global_row_num
    FROM full_join_ws fj
    WHERE
      fj.i_current_price > 100.00                -- predicate 1
      AND fj.s_store_name IS NOT NULL             -- predicate 2
      AND fj.t_hour BETWEEN 9 AND 17              -- predicate 3
      AND fj.ca_gmt_offset BETWEEN -8 AND -5      -- predicate 4
      AND EXISTS (
            SELECT 1
            FROM catalog_sales cs
            JOIN call_center cc
              ON cs.cs_call_center_sk = cc.cc_call_center_sk
            WHERE cs.cs_item_sk = fj.ss_item_sk
              AND cs.cs_sold_date_sk = fj.ss_sold_date_sk
              AND cc.cc_country = 'United States'
      )
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            JOIN ship_mode sm
              ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
            WHERE cr.cr_order_number = fj.ss_ticket_number
              AND sm.sm_carrier = 'UPS'
      )
  )
SELECT *
FROM final
ORDER BY global_row_num
OFFSET 20 LIMIT 100
