WITH cs AS (
  SELECT cs.cs_order_number,
         cs.cs_sold_date_sk,
         cs.cs_net_paid,
         d.d_year
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
),
ws AS (
  SELECT ws.ws_order_number,
         ws.ws_sold_date_sk,
         ws.ws_net_paid,
         d.d_year
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
),
full_join AS (
  SELECT COALESCE(cs.cs_order_number, ws.ws_order_number) AS order_number,
         COALESCE(cs.d_year, ws.d_year) AS year,
         cs.cs_net_paid AS cs_net,
         ws.ws_net_paid AS ws_net
  FROM cs
  FULL OUTER JOIN ws ON cs.cs_order_number = ws.ws_order_number
),
yearly_totals AS (
  SELECT fj.order_number,
         fj.year,
         fj.cs_net,
         fj.ws_net,
         lt.total_cs_net,
         lt.total_ws_net
  FROM full_join fj
  CROSS JOIN LATERAL (
    SELECT SUM(c.cs_net_paid) AS total_cs_net,
           SUM(w.ws_net_paid) AS total_ws_net
    FROM catalog_sales c
    JOIN date_dim d ON c.cs_sold_date_sk = d.d_date_sk
    JOIN web_sales w ON w.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = fj.year
  ) lt
)
SELECT order_number,
       year,
       cs_net,
       ws_net,
       total_cs_net,
       total_ws_net
FROM (
    SELECT order_number, year, cs_net, ws_net, total_cs_net, total_ws_net
    FROM yearly_totals
    WHERE year > (SELECT MAX(d_year) FROM date_dim WHERE d_year < 2000)
    UNION
    SELECT order_number, year, cs_net, ws_net, total_cs_net, total_ws_net
    FROM yearly_totals
    WHERE cs_net IS NULL AND ws_net IS NOT NULL
) AS u
EXCEPT
SELECT order_number, year, cs_net, ws_net, total_cs_net, total_ws_net
FROM yearly_totals
WHERE ws_net IS NULL
ORDER BY year DESC, order_number
LIMIT 100
