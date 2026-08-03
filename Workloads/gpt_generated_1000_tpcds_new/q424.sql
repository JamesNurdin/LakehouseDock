WITH sampled_inventory AS (
   SELECT *
   FROM inventory
   TABLESAMPLE BERNOULLI (10)
),
base1 AS (
   SELECT
       s.s_store_id,
       d_sold.d_year,
       wp.wp_type,
       SUM(cs.cs_net_paid)                     AS total_net_paid,
       AVG(cs.cs_ext_tax)                      AS avg_ext_tax,
       COUNT(DISTINCT cs.cs_order_number)      AS order_cnt,
       MIN(cs.cs_list_price)                   AS min_list_price,
       MAX(i.inv_quantity_on_hand)             AS max_inv_qty
   FROM catalog_sales cs
   JOIN date_dim d_sold               ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN sampled_inventory i          ON i.inv_date_sk = d_sold.d_date_sk
   JOIN store_returns sr              ON sr.sr_returned_date_sk = d_sold.d_date_sk
   JOIN store s                       ON sr.sr_store_sk = s.s_store_sk
   JOIN web_page wp                  ON wp.wp_creation_date_sk = d_sold.d_date_sk
   WHERE cs.cs_ext_list_price > 1000
     AND cs.cs_quantity BETWEEN 1 AND 5
     AND d_sold.d_year = 2001
     AND i.inv_quantity_on_hand > 100
     AND s.s_floor_space > 8000000
     AND wp.wp_type = 'article'
   GROUP BY s.s_store_id, d_sold.d_year, wp.wp_type
),
base2 AS (
   SELECT
       s.s_store_id,
       d_ship.d_year,
       wp.wp_type,
       SUM(cs.cs_net_paid)                     AS total_net_paid,
       AVG(cs.cs_ext_tax)                      AS avg_ext_tax,
       COUNT(DISTINCT cs.cs_order_number)      AS order_cnt,
       MIN(cs.cs_list_price)                   AS min_list_price,
       MAX(i.inv_quantity_on_hand)             AS max_inv_qty
   FROM catalog_sales cs
   JOIN date_dim d_ship               ON cs.cs_ship_date_sk = d_ship.d_date_sk
   JOIN sampled_inventory i          ON i.inv_date_sk = d_ship.d_date_sk
   JOIN store_returns sr              ON sr.sr_returned_date_sk = d_ship.d_date_sk
   JOIN store s                       ON sr.sr_store_sk = s.s_store_sk
   JOIN web_page wp                  ON wp.wp_access_date_sk = d_ship.d_date_sk
   WHERE cs.cs_ext_list_price > 2000
     AND cs.cs_quantity BETWEEN 2 AND 8
     AND d_ship.d_year = 2001
     AND i.inv_quantity_on_hand > 150
     AND s.s_floor_space > 8000000
     AND wp.wp_type = 'article'
   GROUP BY s.s_store_id, d_ship.d_year, wp.wp_type
),
store_excluded AS (
   SELECT s_store_id FROM store
   EXCEPT
   SELECT s_store_id FROM store WHERE s_floor_space < 8000000
)
SELECT
    u.s_store_id,
    u.d_year,
    u.wp_type,
    u.total_net_paid,
    u.avg_ext_tax,
    u.order_cnt,
    u.min_list_price,
    u.max_inv_qty
FROM (
   SELECT * FROM base1
   UNION DISTINCT
   SELECT * FROM base2
) u
WHERE u.s_store_id IN (SELECT s_store_id FROM store_excluded)
ORDER BY u.total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
