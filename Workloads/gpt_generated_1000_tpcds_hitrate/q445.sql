WITH filtered_sales AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_ext_sales_price,
    ss.ss_net_paid,
    st.s_store_id,
    st.s_store_name,
    st.s_city,
    st.s_state,
    td.t_hour
  FROM tpcds.store_sales ss
  JOIN tpcds.store st
    ON ss.ss_store_sk = st.s_store_sk
  JOIN tpcds.time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE regexp_like(st.s_store_name, '^A.*')
    AND st.s_city LIKE '%York%'
    AND EXISTS (
      SELECT 1
      FROM tpcds.promotion p
      WHERE p.p_promo_sk = ss.ss_promo_sk
        AND regexp_extract(p.p_promo_name, '(\\d{4})', 1) = CAST(td.t_hour AS VARCHAR)
    )
),
overall_total AS (
  SELECT SUM(ss_ext_sales_price) AS total_sales_all
  FROM tpcds.store_sales
)
SELECT
  COALESCE(st_id, 'ALL') AS store_id,
  COALESCE(CAST(hour AS VARCHAR), 'ALL') AS hour,
  MIN(CONCAT(s_city, ', ', s_state)) AS location,
  SUM(ext_sales) AS total_sales,
  COUNT(DISTINCT cust_sk) AS distinct_customers,
  COUNT(DISTINCT item_sk) AS distinct_items,
  CASE WHEN SUM(ext_sales) > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
  ROUND(
    (SUM(ext_sales) / (SELECT total_sales_all FROM overall_total)) * 100,
    2
  ) AS pct_of_total
FROM (
  SELECT
    ss_store_sk,
    ss_sold_time_sk,
    ss_item_sk,
    ss_customer_sk,
    ss_ext_sales_price AS ext_sales,
    s_store_id AS st_id,
    s_city,
    s_state,
    t_hour AS hour,
    ss_customer_sk AS cust_sk,
    ss_item_sk AS item_sk
  FROM filtered_sales
) f
GROUP BY ROLLUP (st_id, hour)
ORDER BY total_sales DESC
LIMIT 100
