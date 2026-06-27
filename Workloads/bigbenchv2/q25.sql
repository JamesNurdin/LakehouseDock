WITH temp AS (
  SELECT
    ss.ss_customer_id AS cid,
    ss.ss_transaction_id AS oid,
    date_diff('day', DATE '1900-01-01', CAST(TRY_CAST(ss.ss_ts AS timestamp) AS date)) AS dateid,
    SUM(ss.ss_quantity * i.i_price) AS amount
  FROM iceberg.bigbenchv2_sf1.store_sales ss
  JOIN iceberg.bigbenchv2_sf1.items i
    ON ss.ss_item_id = i.i_item_id
  WHERE CAST(TRY_CAST(ss.ss_ts AS timestamp) AS date) > DATE '2013-01-02'
    AND ss.ss_customer_id IS NOT NULL
  GROUP BY
    ss.ss_customer_id,
    ss.ss_transaction_id,
    ss.ss_ts

  UNION ALL

  SELECT
    ws.ws_customer_id AS cid,
    ws.ws_transaction_id AS oid,
    date_diff('day', DATE '1900-01-01', CAST(TRY_CAST(ws.ws_ts AS timestamp) AS date)) AS dateid,
    SUM(ws.ws_quantity * i.i_price) AS amount
  FROM iceberg.bigbenchv2_sf1.web_sales ws
  JOIN iceberg.bigbenchv2_sf1.items i
    ON ws.ws_item_id = i.i_item_id
  WHERE CAST(TRY_CAST(ws.ws_ts AS timestamp) AS date) > DATE '2013-01-02'
    AND ws.ws_customer_id IS NOT NULL
  GROUP BY
    ws.ws_customer_id,
    ws.ws_transaction_id,
    ws.ws_ts
)

SELECT
  CAST(cid AS integer) AS cid,
  CASE WHEN 37621 - MAX(dateid) < 60 THEN 1 ELSE 0 END AS recency,
  COUNT(oid) AS frequency,
  CAST(SUM(amount) AS integer) AS totalspend
FROM temp
GROUP BY cid