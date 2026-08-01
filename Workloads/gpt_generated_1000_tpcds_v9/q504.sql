WITH sales_agg AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_list_price) AS avg_list_price,
        MAX(ss_ext_tax) AS max_ext_tax,
        MIN(ss_ext_tax) AS min_ext_tax,
        COUNT(*) AS transaction_count
    FROM store_sales
    WHERE ss_net_paid_inc_tax > 1000
      AND ss_ext_tax < 50
      AND ss_list_price >= 20
      AND ss_list_price <= 200
      AND ss_quantity >= 1
      AND ss_sold_date_sk >= 2450815
      AND ss_sold_date_sk <= 2450830
    GROUP BY ss_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_zip,
    sa.total_net_paid_inc_tax,
    sa.total_quantity,
    sa.avg_list_price,
    sa.max_ext_tax,
    sa.min_ext_tax,
    sa.transaction_count
FROM sales_agg sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
  AND s.s_zip IN ('26192', '33951')
  AND s.s_street_name = 'Spring'
ORDER BY sa.total_net_paid_inc_tax DESC
LIMIT 100
