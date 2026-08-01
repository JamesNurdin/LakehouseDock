WITH active_promos AS (
    SELECT p_promo_sk, p_cost
    FROM promotion
    WHERE p_discount_active = 'Y'
),
store_sales_agg AS (
    SELECT
        'Store' AS sales_source,
        s.s_store_name AS entity_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_cnt,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE
            WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High'
            ELSE 'Low'
        END AS profit_category,
        (SELECT AVG(p2.p_cost) FROM promotion p2) AS avg_promo_cost
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN active_promos ap ON ss.ss_promo_sk = ap.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_name
),
catalog_sales_agg AS (
    SELECT
        'Catalog' AS sales_source,
        cp.cp_department AS entity_name,
        COUNT(DISTINCT cs.cs_order_number) AS total_sales_cnt,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE
            WHEN SUM(cs.cs_net_profit) > 20000 THEN 'High'
            ELSE 'Low'
        END AS profit_category,
        (SELECT AVG(p2.p_cost) FROM promotion p2) AS avg_promo_cost
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN active_promos ap ON cs.cs_promo_sk = ap.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_department = 'Electronics'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cp.cp_department
)
SELECT
    sales_source,
    entity_name,
    total_sales_cnt,
    total_net_paid,
    profit_category,
    avg_promo_cost
FROM store_sales_agg
UNION ALL
SELECT
    sales_source,
    entity_name,
    total_sales_cnt,
    total_net_paid,
    profit_category,
    avg_promo_cost
FROM catalog_sales_agg
ORDER BY total_sales_cnt DESC
LIMIT 100
