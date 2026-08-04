WITH
  sales_by_call_center AS (
    SELECT
      'CallCenter' AS entity_type,
      cc.cc_name    AS name,
      t.hour_part  AS part,
      SUM(cs.cs_ext_sales_price) AS metric
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    CROSS JOIN UNNEST(split(cc.cc_hours, '-')) AS t(hour_part)
    WHERE d.d_year = 2022
    GROUP BY cc.cc_name, t.hour_part
  ),
  web_sites_2022 AS (
    SELECT
      'WebSite' AS entity_type,
      ws.web_name  AS name,
      t.part       AS part,
      AVG(ws.web_gmt_offset) AS metric
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    CROSS JOIN UNNEST(split(ws.web_name, ' ')) AS t(part)
    WHERE d.d_year = 2022
      AND ws.web_name IN (SELECT cc.cc_name FROM call_center cc WHERE cc.cc_state = 'CA')
    GROUP BY ws.web_name, t.part
  )
SELECT entity_type, name, part, metric
FROM sales_by_call_center
UNION ALL
SELECT entity_type, name, part, metric
FROM web_sites_2022
ORDER BY entity_type, name, part
LIMIT 100
