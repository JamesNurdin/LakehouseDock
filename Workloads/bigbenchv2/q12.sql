WITH logs AS (
  SELECT
    TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS wl_customer_id,
    TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) AS wl_item_id,
    NULLIF(element_at(split(line, '|'), 4), '') AS wl_webpage_name,
    TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_timestamp
  FROM iceberg.bigbenchv2_sf1.web_logs
),
wcs_view AS (
  SELECT
    l.wl_item_id,
    l.wl_customer_id,
    l.wl_timestamp,
    i.i_category_name
  FROM logs l
  JOIN iceberg.bigbenchv2_sf1.items i
    ON l.wl_item_id = i.i_item_id
  WHERE l.wl_customer_id IS NOT NULL
    AND CAST(l.wl_timestamp AS date) BETWEEN DATE '2014-09-02' AND DATE '2014-10-02'
    AND i.i_category_name IN ('cat#03', 'cat#11')
),
store_view AS (
  SELECT
    ss.ss_item_id,
    ss.ss_customer_id,
    TRY_CAST(ss.ss_ts AS timestamp) AS ss_ts,
    i.i_category_name
  FROM iceberg.bigbenchv2_sf1.store_sales ss
  JOIN iceberg.bigbenchv2_sf1.items i
    ON ss.ss_item_id = i.i_item_id
  WHERE ss.ss_customer_id IS NOT NULL
    AND CAST(TRY_CAST(ss.ss_ts AS timestamp) AS date) BETWEEN DATE '2014-09-02' AND DATE '2014-12-02'
    AND i.i_category_name IN ('cat#03', 'cat#11')
)
SELECT DISTINCT
  CAST(wc.wl_timestamp AS varchar) AS c_date,
  CAST(st.ss_ts AS varchar) AS s_date,
  wc.wl_item_id AS i_id,
  wc.wl_customer_id AS u_id
FROM wcs_view wc
JOIN store_view st
  ON wc.wl_customer_id = st.ss_customer_id
WHERE wc.wl_timestamp < st.ss_ts
  AND wc.i_category_name = st.i_category_name