WITH
  store_full AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      sr.sr_return_amt,
      sr.sr_ticket_number,
      sr.sr_store_sk AS sr_store_sk
    FROM store s
    FULL OUTER JOIN store_returns sr
      ON sr.sr_store_sk = s.s_store_sk
  ),
  unioned_data AS (
    /* First branch – Sports items */
    SELECT
      s_full.s_store_name AS store_name,
      i_sales.i_category   AS item_category,
      p.p_promo_name       AS promotion_name,
      ss.ss_ext_sales_price AS sales_amount,
      COALESCE(s_full.sr_return_amt, 0) + COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0) AS return_amount,
      c.c_customer_id      AS customer_id
    FROM store_sales ss
    JOIN time_dim td_sold
      ON ss.ss_sold_time_sk = td_sold.t_time_sk
    JOIN item i_sales
      ON ss.ss_item_sk = i_sales.i_item_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_full s_full
      ON ss.ss_store_sk = s_full.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv
      ON i_sales.i_item_sk = inv.inv_item_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_item_sk = i_sales.i_item_sk
    LEFT JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i_sales.i_item_sk
    LEFT JOIN time_dim td_ret
      ON cr.cr_returned_time_sk = td_ret.t_time_sk
    WHERE ss.ss_item_sk IN (
      SELECT i_f.i_item_sk
      FROM item i_f
      WHERE i_f.i_category = 'Sports'
    )
    UNION DISTINCT
    /* Second branch – Clothing items */
    SELECT
      s_full.s_store_name AS store_name,
      i_sales2.i_category   AS item_category,
      p2.p_promo_name       AS promotion_name,
      ss2.ss_ext_sales_price AS sales_amount,
      COALESCE(s_full.sr_return_amt, 0) + COALESCE(cr2.cr_return_amount, 0) + COALESCE(wr2.wr_return_amt, 0) AS return_amount,
      c2.c_customer_id      AS customer_id
    FROM store_sales ss2
    JOIN time_dim td_sold2
      ON ss2.ss_sold_time_sk = td_sold2.t_time_sk
    JOIN item i_sales2
      ON ss2.ss_item_sk = i_sales2.i_item_sk
    JOIN customer c2
      ON ss2.ss_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2
      ON ss2.ss_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2
      ON ss2.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN store_full s_full
      ON ss2.ss_store_sk = s_full.s_store_sk
    JOIN promotion p2
      ON ss2.ss_promo_sk = p2.p_promo_sk
    LEFT JOIN inventory inv2
      ON i_sales2.i_item_sk = inv2.inv_item_sk
    LEFT JOIN catalog_returns cr2
      ON cr2.cr_item_sk = i_sales2.i_item_sk
    LEFT JOIN call_center cc2
      ON cr2.cr_call_center_sk = cc2.cc_call_center_sk
    LEFT JOIN ship_mode sm2
      ON cr2.cr_ship_mode_sk = sm2.sm_ship_mode_sk
    LEFT JOIN web_returns wr2
      ON wr2.wr_item_sk = i_sales2.i_item_sk
    LEFT JOIN time_dim td_ret2
      ON cr2.cr_returned_time_sk = td_ret2.t_time_sk
    WHERE ss2.ss_item_sk IN (
      SELECT i_f2.i_item_sk
      FROM item i_f2
      WHERE i_f2.i_category = 'Clothing'
    )
  )
SELECT
  store_name,
  item_category,
  promotion_name,
  SUM(sales_amount)   AS total_sales_amount,
  SUM(return_amount)  AS total_return_amount,
  COUNT(DISTINCT customer_id) AS distinct_customers
FROM unioned_data
GROUP BY
  store_name,
  item_category,
  promotion_name
ORDER BY total_sales_amount DESC
LIMIT 100
