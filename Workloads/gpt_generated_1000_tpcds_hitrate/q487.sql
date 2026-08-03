WITH
  /* Sales from the catalog */
  catalog_sales_agg AS (
    SELECT
      i1.i_item_id,
      i1.i_category,
      cp.cp_department AS dept_or_store,
      cd1.cd_gender AS gender,
      hd1.hd_income_band_sk AS income_band,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i1 ON cs.cs_item_sk = i1.i_item_sk
    JOIN promotion p1 ON cs.cs_promo_sk = p1.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c1 ON cs.cs_bill_customer_sk = c1.c_customer_sk
    JOIN customer_demographics cd1 ON cs.cs_bill_cdemo_sk = cd1.cd_demo_sk
    JOIN household_demographics hd1 ON cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
    JOIN customer_address ca1 ON cs.cs_bill_addr_sk = ca1.ca_address_sk
    GROUP BY i1.i_item_id, i1.i_category, cp.cp_department, cd1.cd_gender, hd1.hd_income_band_sk
  ),

  /* Sales from the store */
  store_sales_agg AS (
    SELECT
      i2.i_item_id,
      i2.i_category,
      s.s_store_name AS dept_or_store,
      cd2.cd_gender AS gender,
      hd2.hd_income_band_sk AS income_band,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
    JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c2 ON ss.ss_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2 ON ss.ss_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
    GROUP BY i2.i_item_id, i2.i_category, s.s_store_name, cd2.cd_gender, hd2.hd_income_band_sk
  ),

  /* Returns from the catalog */
  catalog_returns_agg AS (
    SELECT
      i3.i_item_id,
      i3.i_category,
      cp.cp_department AS dept_or_store,
      cd3.cd_gender AS gender,
      hd3.hd_income_band_sk AS income_band,
      SUM(cr.cr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN item i3 ON cr.cr_item_sk = i3.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c3 ON cr.cr_refunded_customer_sk = c3.c_customer_sk
    JOIN customer_demographics cd3 ON cr.cr_refunded_cdemo_sk = cd3.cd_demo_sk
    JOIN household_demographics hd3 ON cr.cr_refunded_hdemo_sk = hd3.hd_demo_sk
    GROUP BY i3.i_item_id, i3.i_category, cp.cp_department, cd3.cd_gender, hd3.hd_income_band_sk
  ),

  /* Returns from the store */
  store_returns_agg AS (
    SELECT
      i4.i_item_id,
      i4.i_category,
      s.s_store_name AS dept_or_store,
      cd4.cd_gender AS gender,
      hd4.hd_income_band_sk AS income_band,
      SUM(sr.sr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i4 ON sr.sr_item_sk = i4.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c4 ON sr.sr_customer_sk = c4.c_customer_sk
    JOIN customer_demographics cd4 ON sr.sr_cdemo_sk = cd4.cd_demo_sk
    JOIN household_demographics hd4 ON sr.sr_hdemo_sk = hd4.hd_demo_sk
    GROUP BY i4.i_item_id, i4.i_category, s.s_store_name, cd4.cd_gender, hd4.hd_income_band_sk
  ),

  /* Returns from the web */
  web_returns_agg AS (
    SELECT
      i5.i_item_id,
      i5.i_category,
      wp.wp_type AS dept_or_store,
      cd5.cd_gender AS gender,
      hd5.hd_income_band_sk AS income_band,
      SUM(wr.wr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN item i5 ON wr.wr_item_sk = i5.i_item_sk
    JOIN customer c5 ON wr.wr_refunded_customer_sk = c5.c_customer_sk
    JOIN customer_demographics cd5 ON wr.wr_refunded_cdemo_sk = cd5.cd_demo_sk
    JOIN household_demographics hd5 ON wr.wr_refunded_hdemo_sk = hd5.hd_demo_sk
    GROUP BY i5.i_item_id, i5.i_category, wp.wp_type, cd5.cd_gender, hd5.hd_income_band_sk
  ),

  /* Union of all sales */
  sales_union AS (
    SELECT i_item_id, i_category, dept_or_store, gender, income_band, total_net_paid, sales_cnt
    FROM catalog_sales_agg
    UNION
    SELECT i_item_id, i_category, dept_or_store, gender, income_band, total_net_paid, sales_cnt
    FROM store_sales_agg
  ),

  /* Union of all returns */
  returns_union AS (
    SELECT i_item_id, i_category, dept_or_store, gender, income_band, total_net_loss, return_cnt
    FROM catalog_returns_agg
    UNION
    SELECT i_item_id, i_category, dept_or_store, gender, income_band, total_net_loss, return_cnt
    FROM store_returns_agg
    UNION
    SELECT i_item_id, i_category, dept_or_store, gender, income_band, total_net_loss, return_cnt
    FROM web_returns_agg
  ),

  /* Full outer join between sales and returns */
  sales_returns_full AS (
    SELECT
      COALESCE(su.i_item_id, ru.i_item_id) AS i_item_id,
      COALESCE(su.i_category, ru.i_category) AS i_category,
      COALESCE(su.dept_or_store, ru.dept_or_store) AS dept_or_store,
      COALESCE(su.gender, ru.gender) AS gender,
      COALESCE(su.income_band, ru.income_band) AS income_band,
      su.total_net_paid,
      su.sales_cnt,
      ru.total_net_loss,
      ru.return_cnt
    FROM sales_union su
    FULL OUTER JOIN returns_union ru
      ON su.i_item_id = ru.i_item_id
     AND su.i_category = ru.i_category
     AND su.income_band = ru.income_band
  ),

  /* Small dimension for cross join */
  income_band_small AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk IN (1, 2, 3)
  ),

  /* Computed set for cross join */
  const_vals AS (
    SELECT 1 AS const_val UNION ALL SELECT 2 UNION ALL SELECT 3
  ),

  /* Final aggregation with cross join, ranking and having */
  final_agg AS (
    SELECT
      sr.i_item_id,
      sr.i_category,
      sr.dept_or_store,
      sr.gender,
      sr.income_band,
      SUM(COALESCE(sr.total_net_paid, 0)) AS total_sales,
      SUM(COALESCE(sr.total_net_loss, 0)) AS total_losses,
      SUM(COALESCE(sr.sales_cnt, 0)) AS sales_transactions,
      SUM(COALESCE(sr.return_cnt, 0)) AS return_transactions,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cv.const_val,
      RANK() OVER (PARTITION BY sr.i_category ORDER BY SUM(COALESCE(sr.total_net_paid, 0)) DESC) AS sales_rank
    FROM sales_returns_full sr
    FULL OUTER JOIN income_band_small ib ON sr.income_band = ib.ib_income_band_sk
    CROSS JOIN const_vals cv
    GROUP BY
      sr.i_item_id,
      sr.i_category,
      sr.dept_or_store,
      sr.gender,
      sr.income_band,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cv.const_val,
      sr.dept_or_store,
      sr.gender,
      sr.income_band
    HAVING SUM(COALESCE(sr.total_net_paid, 0)) > 1000
  )
SELECT *
FROM final_agg
ORDER BY total_sales DESC
LIMIT 100
