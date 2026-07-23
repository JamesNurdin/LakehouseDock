WITH store_sales_agg AS (
    SELECT
        ss_store_sk,
        ss_promo_sk,
        ss_addr_sk,
        ss_sold_time_sk,
        SUM(ss_ext_sales_price) AS sum_ext_sales_price,
        SUM(ss_net_paid) AS sum_net_paid,
        COUNT(*) AS cnt_transactions,
        AVG(ss_ext_tax) AS avg_ext_tax,
        MAX(ss_ext_wholesale_cost) AS max_wholesale_cost
    FROM store_sales
    WHERE ss_ext_wholesale_cost < 2000
      AND ss_ext_tax BETWEEN 5 AND 50
    GROUP BY ss_store_sk, ss_promo_sk, ss_addr_sk, ss_sold_time_sk
)
SELECT
    s.s_store_name,
    t.t_hour,
    ca_store.ca_state,
    p_store.p_promo_name,
    COUNT(DISTINCT ssa.ss_store_sk) AS store_count,
    SUM(ssa.sum_ext_sales_price) AS total_store_sales,
    SUM(ssa.sum_net_paid) AS total_store_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(cs.cs_net_paid_inc_tax) AS total_catalog_net_paid_inc_tax,
    CASE
        WHEN SUM(ssa.sum_ext_sales_price) > 1000000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS sales_volume_category,
    AVG(ssa.avg_ext_tax) AS avg_store_tax,
    MIN(ssa.max_wholesale_cost) AS min_max_wholesale_cost
FROM store_sales_agg ssa
JOIN store s ON s.s_store_sk = ssa.ss_store_sk
JOIN promotion p_store ON ssa.ss_promo_sk = p_store.p_promo_sk
JOIN customer_address ca_store ON ssa.ss_addr_sk = ca_store.ca_address_sk
JOIN time_dim t ON ssa.ss_sold_time_sk = t.t_time_sk
JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
JOIN promotion p_cat ON cs.cs_promo_sk = p_cat.p_promo_sk
JOIN customer_address ca_cat ON cs.cs_bill_addr_sk = ca_cat.ca_address_sk
WHERE s.s_state = 'CA'
  AND ca_store.ca_state = 'CA'
  AND p_store.p_channel_dmail = 'Y'
  AND p_cat.p_start_date_sk >= 2450316
  AND cs.cs_warehouse_sk IN (1, 3, 12)
  AND cs.cs_net_paid_inc_tax > 500
  AND t.t_hour = 14
GROUP BY
    s.s_store_name,
    t.t_hour,
    ca_store.ca_state,
    p_store.p_promo_name
ORDER BY total_store_sales DESC
LIMIT 100
