WITH agg AS (
    SELECT
        s.s_store_id,
        p.p_promo_id,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(DISTINCT ss.ss_quantity) AS distinct_quantity_sum,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
        max_store.max_sale
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    CROSS JOIN LATERAL (
        SELECT MAX(ss2.ss_ext_sales_price) AS max_sale
        FROM tpcds.store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    ) AS max_store
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY CUBE (s.s_store_id, p.p_promo_id, max_store.max_sale)
),
set1 AS (
    SELECT s_store_id, p_promo_id
    FROM agg
    WHERE sales_category = 'HIGH' AND distinct_customers > 30
),
set2 AS (
    SELECT s_store_id, p_promo_id
    FROM agg
    WHERE distinct_quantity_sum > 15 AND max_sale > 1000
),
intersect_set AS (
    SELECT s_store_id, p_promo_id FROM set1
    INTERSECT
    SELECT s_store_id, p_promo_id FROM set2
)
SELECT
    a.s_store_id,
    a.p_promo_id,
    a.distinct_customers,
    a.distinct_quantity_sum,
    a.distinct_tickets,
    a.sales_category,
    a.max_sale
FROM agg a
JOIN intersect_set i
  ON a.s_store_id = i.s_store_id
 AND a.p_promo_id = i.p_promo_id
ORDER BY a.distinct_customers DESC, a.s_store_id
LIMIT 100
