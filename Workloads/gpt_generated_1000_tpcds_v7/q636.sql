WITH catalog AS (
   SELECT i.i_item_id AS item_id,
          d.d_date AS sale_date,
          cs.cs_net_paid AS net_paid
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2020
     AND cs.cs_quantity > 0
),
web AS (
   SELECT i.i_item_id AS item_id,
          d.d_date AS sale_date,
          ws.ws_net_paid AS net_paid
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2020
     AND ws.ws_quantity > 0
)
SELECT item_id,
       SUM(net_paid) AS total_net_paid
FROM (
   SELECT item_id, net_paid FROM catalog
   UNION ALL
   SELECT item_id, net_paid FROM web
) combined
GROUP BY item_id
ORDER BY total_net_paid DESC
LIMIT 10
