/*
  Goal: Aggregate net paid sales per store for different street‑name patterns, applying regex filters, scalar subquery comparisons, and existence checks, then combine the two result sets with UNION and order by total revenue.
*/
SELECT
    s.s_store_id,
    concat(s.s_street_name, ' ', s.s_street_type) AS full_street,
    d_sold.d_year,
    sum(cs.cs_net_paid) AS total_net_paid,
    count(distinct cs.cs_order_number) AS orders_cnt
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = d_sold.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE regexp_like(s.s_street_name, '^.*[A-Za-z]{4,}$')
  AND s.s_street_name LIKE 'Park%'
  AND cs.cs_list_price < (SELECT MAX(cs_list_price) FROM catalog_sales)
  AND EXISTS (
        SELECT 1 FROM inventory i2
        WHERE i2.inv_item_sk = cs.cs_item_sk
          AND i2.inv_quantity_on_hand > 200
      )
GROUP BY
    s.s_store_id,
    concat(s.s_street_name, ' ', s.s_street_type),
    d_sold.d_year
HAVING sum(cs.cs_net_paid) > (SELECT avg(cs_net_paid) FROM catalog_sales)

UNION

SELECT
    s.s_store_id,
    concat(s.s_street_name, ' ', s.s_street_type) AS full_street,
    d_ship.d_year,
    sum(cs.cs_net_paid) AS total_net_paid,
    count(distinct cs.cs_order_number) AS orders_cnt
FROM catalog_sales cs
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = d_ship.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE regexp_extract(s.s_street_name, '(\\w+)', 1) = 'Avenue'
  AND s.s_street_name LIKE '%Ave'
  AND cs.cs_quantity >= 2
GROUP BY
    s.s_store_id,
    concat(s.s_street_name, ' ', s.s_street_type),
    d_ship.d_year
HAVING sum(cs.cs_net_paid) > 5000

ORDER BY total_net_paid DESC
