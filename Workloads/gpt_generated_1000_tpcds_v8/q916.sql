/*
  goal: Identify stores for the year 2002 that had returns processed through warehouses in Seattle, rank them by total catalog return amount, classify the return magnitude, and expose related promotion and call‑center information while demonstrating advanced SQL features (CTE aggregation, INTERSECT/EXCEPT set logic, TABLESAMPLE, DISTINCT, CASE, window functions, and a RIGHT OUTER JOIN to retain stores with no returns).
*/
WITH agg_cat AS (
    SELECT
        cr_warehouse_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_warehouse_sk
),
intersect_wh AS (
    SELECT cr_warehouse_sk
    FROM catalog_returns
    WHERE cr_return_amount > 100
    INTERSECT
    SELECT w_warehouse_sk
    FROM warehouse
    WHERE w_city = 'Seattle'
),
except_wh AS (
    SELECT w_warehouse_sk
    FROM warehouse
    WHERE w_state = 'CA'
    EXCEPT
    SELECT cr_warehouse_sk
    FROM catalog_returns
    WHERE cr_return_amount < 50
)
SELECT
    s.s_store_name,
    d.d_year,
    t.t_hour,
    agg_cat.total_return_amount,
    CASE
        WHEN agg_cat.total_return_amount >= 10000 THEN 'HIGH'
        WHEN agg_cat.total_return_amount >= 5000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level,
    DENSE_RANK() OVER (PARTITION BY s.s_state ORDER BY agg_cat.total_return_amount DESC) AS state_return_rank,
    cc.cc_name,
    p.p_promo_name
FROM store_returns sr
RIGHT OUTER JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_returned_time_sk = t.t_time_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN agg_cat
    ON agg_cat.cr_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN (
    SELECT DISTINCT p.p_promo_id, p.p_promo_name, p.p_start_date_sk
    FROM promotion p
    TABLESAMPLE BERNOULLI (10)
) p
    ON p.p_start_date_sk = d.d_date_sk
JOIN customer_address ca1
    ON cr.cr_refunded_addr_sk = ca1.ca_address_sk
JOIN customer_address ca2
    ON sr.sr_addr_sk = ca2.ca_address_sk
WHERE d.d_year = 2002
  AND t.t_hour BETWEEN 9 AND 17
  AND w.w_city = 'Seattle'
  AND cr.cr_warehouse_sk IN (SELECT cr_warehouse_sk FROM intersect_wh)
  AND cr.cr_warehouse_sk NOT IN (SELECT w_warehouse_sk FROM except_wh)
ORDER BY agg_cat.total_return_amount DESC
LIMIT 100
