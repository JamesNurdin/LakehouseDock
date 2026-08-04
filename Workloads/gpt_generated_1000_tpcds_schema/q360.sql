WITH catalog_qty AS (
  SELECT
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    l.qty AS quantity
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  CROSS JOIN LATERAL (
    SELECT qty
    FROM UNNEST(array[cs.cs_quantity, cs.cs_quantity * 2]) AS t(qty)
  ) AS l
  WHERE cp.cp_catalog_number = 18
    AND td.t_hour BETWEEN 9 AND 17
),
web_qty AS (
  SELECT
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    l.qty AS quantity
  FROM web_sales ws
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  CROSS JOIN LATERAL (
    SELECT qty
    FROM UNNEST(array[ws.ws_quantity, ws.ws_quantity + 1]) AS t(qty)
  ) AS l
  WHERE ws_site.web_state = 'WA'
    AND td.t_hour BETWEEN 9 AND 17
)
SELECT gender, marital_status, quantity
FROM catalog_qty
INTERSECT
SELECT gender, marital_status, quantity
FROM web_qty
ORDER BY gender, marital_status, quantity
LIMIT 100
