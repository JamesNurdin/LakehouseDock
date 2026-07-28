WITH catalog_part AS (
   SELECT
      cs.cs_sold_date_sk AS date_sk,
      d.d_date AS sale_date,
      i.i_item_id,
      i.i_product_name,
      cs.cs_net_paid_inc_tax AS net_paid,
      cs.cs_quantity AS qty,
      'catalog' AS source
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2001
     AND i.i_category = 'Electronics'
     AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
     )
),
web_part AS (
   SELECT
      ws.ws_sold_date_sk AS date_sk,
      d.d_date AS sale_date,
      i.i_item_id,
      i.i_product_name,
      ws.ws_net_paid_inc_tax AS net_paid,
      ws.ws_quantity AS qty,
      'web' AS source
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2001
     AND wp.wp_type = 'Content'
     AND ws.ws_net_paid_inc_tax > (
        SELECT avg(ws2.ws_net_paid_inc_tax)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
     )
)
SELECT *
FROM catalog_part
UNION ALL
SELECT *
FROM web_part
ORDER BY sale_date, net_paid DESC
