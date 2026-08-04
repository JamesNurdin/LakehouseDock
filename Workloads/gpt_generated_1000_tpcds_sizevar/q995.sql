WITH
  sample_store AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),

  -- First wide join using the sample of store_sales
  joined1 AS (
    SELECT
      ss.ss_sold_date_sk,
      d.d_year,
      i.i_item_id,
      i.i_current_price,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      cr.cr_return_amount,
      cp.cp_catalog_page_number,
      ws.ws_net_paid,
      we.web_name,
      we.web_country
    FROM sample_store ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    WHERE i.i_current_price > 10
      AND ib.ib_lower_bound >= 20000
      AND d.d_year BETWEEN 1999 AND 2002
      AND cp.cp_catalog_page_number IS NOT NULL
      AND we.web_country = 'United States'
      AND EXISTS (
        SELECT 1
        FROM income_band ib2
        WHERE ib2.ib_income_band_sk = ib.ib_income_band_sk
          AND ib2.ib_upper_bound > 50000
      )
  ),

  agg1 AS (
    SELECT
      d_year,
      i_item_id,
      SUM(i_current_price) AS total_price,
      SUM(cr_return_amount) AS total_return,
      SUM(ws_net_paid) AS total_web_paid,
      COUNT(*) AS txn_cnt
    FROM joined1
    GROUP BY CUBE (d_year, i_item_id)
  ),

  -- Second wide join using the full store_sales table (different filters)
  joined2 AS (
    SELECT
      ss.ss_sold_date_sk,
      d.d_year,
      i.i_item_id,
      i.i_current_price,
      hd.hd_income_band_sk,
      ib.ib_upper_bound,
      cr.cr_return_amount,
      cp.cp_catalog_page_number,
      ws.ws_net_paid,
      we.web_name,
      we.web_state
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    WHERE i.i_current_price < 30
      AND ib.ib_upper_bound <= 80000
      AND d.d_year >= 1998
      AND cp.cp_type = 'promo'
      AND we.web_state = 'CA'
  ),

  agg2 AS (
    SELECT
      d_year,
      i_item_id,
      SUM(i_current_price) AS total_price,
      SUM(cr_return_amount) AS total_return,
      SUM(ws_net_paid) AS total_web_paid,
      COUNT(*) AS txn_cnt
    FROM joined2
    GROUP BY CUBE (d_year, i_item_id)
  ),

  -- Union of the two aggregated result sets (distinct by default)
  union_all AS (
    SELECT d_year, i_item_id, total_price, total_return, total_web_paid, txn_cnt
    FROM agg1
    UNION
    SELECT d_year, i_item_id, total_price, total_return, total_web_paid, txn_cnt
    FROM agg2
  ),

  -- Rows that appear only in agg1 (EXCEPT)
  only_in_agg1 AS (
    SELECT d_year, i_item_id FROM agg1
    EXCEPT
    SELECT d_year, i_item_id FROM agg2
  ),

  -- Rows that appear in both agg1 and agg2 (INTERSECT)
  in_both AS (
    SELECT d_year, i_item_id FROM agg1
    INTERSECT
    SELECT d_year, i_item_id FROM agg2
  ),

  final AS (
    SELECT
      u.d_year,
      u.i_item_id,
      u.total_price,
      u.total_return,
      u.total_web_paid,
      u.txn_cnt,
      CASE WHEN o.d_year IS NOT NULL THEN 'OnlyInAgg1' ELSE 'BothOrOnlyInAgg2' END AS presence_flag
    FROM union_all u
    LEFT JOIN only_in_agg1 o
      ON u.d_year = o.d_year AND u.i_item_id = o.i_item_id
    WHERE u.total_price > 0
      AND u.total_return IS NOT NULL
  )
SELECT
  d_year,
  i_item_id,
  total_price,
  total_return,
  total_web_paid,
  txn_cnt,
  presence_flag
FROM final
ORDER BY d_year DESC, total_price DESC
LIMIT 100
