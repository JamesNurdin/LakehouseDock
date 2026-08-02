WITH intersect_items AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    WHERE d_cs.d_year = 2001
    INTERSECT
    SELECT DISTINCT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    WHERE d_ss.d_year = 2001
)
SELECT
    s.s_state,
    d.d_year,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    AVG(ss.ss_quantity) AS avg_store_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    MIN(ss.ss_sales_price) AS min_store_sales_price,
    MAX(ss.ss_sales_price) AS max_store_sales_price
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_cs ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
JOIN intersect_items ii ON cs.cs_item_sk = ii.item_sk
WHERE
    d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND w.w_gmt_offset = -6.00
    AND s.s_state = 'CA'
    AND i.inv_quantity_on_hand > 100
    AND p_ss.p_discount_active = 'N'
    AND NOT EXISTS (
        SELECT 1
        FROM (
            SELECT DISTINCT p2.p_promo_sk
            FROM promotion p2
            WHERE p2.p_discount_active = 'Y'
        ) active_promos
        WHERE active_promos.p_promo_sk = ss.ss_promo_sk
    )
GROUP BY ROLLUP(s.s_state, d.d_year)
ORDER BY total_store_net_paid DESC
LIMIT 100
