WITH online AS (
    SELECT
        ws.ws_customer_id AS c_customer_id,
        SUM(ws.ws_quantity * i.i_price) AS online_revenue
    FROM iceberg.bigbenchv2_sf1.web_sales ws
    JOIN iceberg.bigbenchv2_sf1.items i
      ON ws.ws_item_id = i.i_item_id
    WHERE ws.ws_customer_id IS NOT NULL
    GROUP BY ws.ws_customer_id
),

instore AS (
    SELECT
        ss.ss_customer_id AS c_customer_id,
        SUM(ss.ss_quantity * i.i_price) AS instore_revenue
    FROM iceberg.bigbenchv2_sf1.store_sales ss
    JOIN iceberg.bigbenchv2_sf1.items i
      ON ss.ss_item_id = i.i_item_id
    WHERE ss.ss_customer_id IS NOT NULL
    GROUP BY ss.ss_customer_id
)

SELECT
    SUM(CASE WHEN o.online_revenue >= s.instore_revenue THEN 1 ELSE 0 END) AS online_segment,
    SUM(CASE WHEN o.online_revenue < s.instore_revenue THEN 1 ELSE 0 END) AS instore_segment
FROM iceberg.bigbenchv2_sf1.customers c
JOIN online o
  ON c.c_customer_id = o.c_customer_id
JOIN instore s
  ON c.c_customer_id = s.c_customer_id