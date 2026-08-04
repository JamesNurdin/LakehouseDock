WITH
  base AS (
    SELECT
      d.d_year,
      cs.cs_ext_sales_price,
      sr.sr_return_amt,
      s.s_store_id,
      sm.sm_type,
      w.w_gmt_offset,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_income_band_sk,
      wp.wp_autogen_flag
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND cs.cs_ext_sales_price > 100
      AND w.w_gmt_offset = -5.00
      AND s.s_state = 'CA'
      AND wp.wp_autogen_flag = 'Y'
      AND sr.sr_return_amt > 30
  ),
  sales_rank AS (
    SELECT
      s_store_id,
      cs_ext_sales_price AS metric,
      ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY cs_ext_sales_price DESC) AS rn,
      'sales' AS src
    FROM base
    WHERE cs_ext_sales_price > 150
  ),
  returns_rank AS (
    SELECT
      s_store_id,
      sr_return_amt AS metric,
      ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY sr_return_amt DESC) AS rn,
      'returns' AS src
    FROM base
    WHERE sr_return_amt > 80
  ),
  union_set AS (
    SELECT s_store_id, metric, src FROM sales_rank WHERE rn <= 3
    UNION
    SELECT s_store_id, metric, src FROM returns_rank WHERE rn <= 3
  ),
  except_set AS (
    SELECT s_store_id FROM sales_rank
    EXCEPT
    SELECT s_store_id FROM returns_rank
  ),
  full_join AS (
    SELECT
      COALESCE(s.s_store_id, r.s_store_id) AS s_store_id,
      s.metric AS sales_metric,
      r.metric AS return_metric
    FROM sales_rank s
    FULL OUTER JOIN returns_rank r ON s.s_store_id = r.s_store_id
  )
SELECT
  f.s_store_id,
  f.sales_metric,
  f.return_metric,
  u.metric,
  u.src
FROM full_join f
JOIN union_set u ON u.s_store_id = f.s_store_id
WHERE f.s_store_id IN (SELECT s_store_id FROM except_set)
ORDER BY f.s_store_id ASC, u.metric DESC
LIMIT 100
