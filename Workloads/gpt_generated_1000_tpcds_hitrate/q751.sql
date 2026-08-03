WITH sales_by_store AS (
    SELECT s.s_store_id,
           i.i_category,
           SUM(ss.ss_net_paid) AS total_net_paid,
           COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
           AVG(ss.ss_ext_tax) AS avg_tax
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY s.s_store_id, i.i_category
),
catalog_sales_by_category AS (
    SELECT cp.cp_department,
           i.i_category,
           SUM(cs.cs_net_paid) AS total_net_paid,
           COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY cp.cp_department, i.i_category
),
common_store_ids AS (
    SELECT s_store_id FROM store
    WHERE s_floor_space > 8000000
    INTERSECT
    SELECT s.s_store_id
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_id
)
SELECT COALESCE(sbs.s_store_id, 'UNKNOWN') AS store_id,
       COALESCE(sbs.i_category, csbc.i_category) AS category,
       COALESCE(sbs.total_net_paid, 0) AS store_total_net_paid,
       COALESCE(csbc.total_net_paid, 0) AS catalog_total_net_paid,
       sbs.distinct_tickets,
       csbc.distinct_orders,
       promo.total_promo_cost
FROM sales_by_store sbs
FULL OUTER JOIN catalog_sales_by_category csbc
    ON sbs.i_category = csbc.i_category
LEFT JOIN LATERAL (
    SELECT SUM(p.p_cost) AS total_promo_cost
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE i.i_category = COALESCE(sbs.i_category, csbc.i_category)
) AS promo ON true
WHERE sbs.s_store_id IN (SELECT s_store_id FROM common_store_ids)
LIMIT 100
