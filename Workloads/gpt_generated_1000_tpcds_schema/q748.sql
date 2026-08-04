WITH agg_a AS (
   SELECT c.c_customer_id,
          SUM(sr.sr_return_amt) AS total_return_amt,
          SUM(sr.sr_return_quantity) AS total_qty,
          CASE WHEN SUM(sr.sr_return_quantity) > 50 THEN 'High' ELSE 'Low' END AS qty_category
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2002
     AND ca.ca_state = 'CA'
     AND sr.sr_return_quantity > 10
     AND ca.ca_city = 'Lincoln'
   GROUP BY c.c_customer_id
),
agg_b AS (
   SELECT c.c_customer_id,
          SUM(sr.sr_return_amt) AS total_return_amt,
          SUM(sr.sr_return_quantity) AS total_qty,
          CASE WHEN SUM(sr.sr_return_quantity) > 30 THEN 'Medium' ELSE 'Small' END AS qty_category
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2001
     AND ca.ca_state = 'TX'
     AND sr.sr_return_quantity BETWEEN 5 AND 20
     AND ca.ca_street_name LIKE 'Pine%'
   GROUP BY c.c_customer_id
),
union_set AS (
   SELECT c_customer_id, total_return_amt, total_qty, qty_category FROM agg_a
   UNION
   SELECT c_customer_id, total_return_amt, total_qty, qty_category FROM agg_b
),
except_set AS (
   SELECT c_customer_id FROM agg_a
   EXCEPT
   SELECT c_customer_id FROM agg_b
),
intersect_set AS (
   SELECT c_customer_id FROM agg_a
   INTERSECT
   SELECT c_customer_id FROM agg_b
),
final AS (
   SELECT u.c_customer_id,
          u.total_return_amt,
          u.total_qty,
          u.qty_category,
          (SELECT AVG(total_return_amt) FROM union_set) AS avg_return_overall,
          CASE WHEN u.total_return_amt > (SELECT AVG(total_return_amt) FROM union_set) THEN 1 ELSE 0 END AS above_avg_flag,
          EXISTS (SELECT 1 FROM except_set e WHERE e.c_customer_id = u.c_customer_id) AS is_in_except,
          EXISTS (SELECT 1 FROM intersect_set i WHERE i.c_customer_id = u.c_customer_id) AS is_in_intersect
   FROM union_set u
   WHERE u.qty_category IN ('High', 'Medium')
)
SELECT c_customer_id,
       total_return_amt,
       total_qty,
       qty_category,
       avg_return_overall,
       above_avg_flag,
       is_in_except,
       is_in_intersect
FROM final
ORDER BY total_return_amt DESC
LIMIT 100
