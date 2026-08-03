WITH
  sales_agg AS (
    SELECT
      cp.cp_catalog_page_id,
      d.d_year,
      d.d_month_seq,
      sm.sm_carrier,
      SUM(cs.cs_net_paid) AS total_sales,
      COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(cp.cp_description, '(?i)sale')
      AND sm.sm_carrier LIKE 'B%'
    GROUP BY cp.cp_catalog_page_id, d.d_year, d.d_month_seq, sm.sm_carrier
  ),
  returns_agg AS (
    SELECT
      cp.cp_catalog_page_id,
      d.d_year,
      d.d_month_seq,
      sm.sm_carrier,
      SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(cp.cp_description, '(?i)sale')
      AND sm.sm_carrier LIKE 'B%'
    GROUP BY cp.cp_catalog_page_id, d.d_year, d.d_month_seq, sm.sm_carrier
  )
SELECT
  combined.cp_catalog_page_id,
  combined.d_year,
  combined.d_month_seq,
  combined.sm_carrier,
  combined.total_sales,
  combined.total_returns,
  combined.sales_category,
  combined.ca_store_count,
  CONCAT(combined.cp_catalog_page_id, '-', combined.sm_carrier) AS page_carrier_key,
  SUBSTRING(combined.sm_carrier, 1, 3) AS carrier_prefix,
  REGEXP_EXTRACT(combined.sales_category, '(HIGH|LOW|NO_SALES)', 1) AS sales_flag
FROM (
  SELECT
    s.cp_catalog_page_id,
    s.d_year,
    s.d_month_seq,
    s.sm_carrier,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    CASE WHEN s.total_sales > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
    (SELECT COUNT(DISTINCT st.s_store_sk) FROM store st WHERE st.s_state = 'CA') AS ca_store_count
  FROM sales_agg s
  LEFT JOIN returns_agg r
    ON s.cp_catalog_page_id = r.cp_catalog_page_id
   AND s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.sm_carrier = r.sm_carrier

  UNION DISTINCT

  SELECT
    r.cp_catalog_page_id,
    r.d_year,
    r.d_month_seq,
    r.sm_carrier,
    0 AS total_sales,
    r.total_returns,
    'NO_SALES' AS sales_category,
    (SELECT COUNT(DISTINCT st.s_store_sk) FROM store st WHERE st.s_state = 'CA') AS ca_store_count
  FROM returns_agg r
  WHERE NOT EXISTS (
    SELECT 1 FROM sales_agg s2
    WHERE s2.cp_catalog_page_id = r.cp_catalog_page_id
      AND s2.d_year = r.d_year
      AND s2.d_month_seq = r.d_month_seq
      AND s2.sm_carrier = r.sm_carrier
  )
) AS combined
ORDER BY combined.d_year DESC, combined.d_month_seq, combined.total_sales DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
