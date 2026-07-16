SELECT
    i.i_category AS category,
    i.i_brand AS brand,
    sm.sm_carrier AS carrier,
    date_trunc('month', date_parse(cast(cs.cs_sold_date_sk as varchar), '%Y%m%d')) AS month,
    COALESCE(SUM(cs.cs_net_profit), 0) AS catalog_net_profit,
    COALESCE(SUM(ss.ss_net_profit), 0) AS store_net_profit,
    COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
FROM catalog_sales cs
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
WHERE cs.cs_warehouse_sk IN (14, 2, 7, 13, 16)
  AND cs.cs_net_paid_inc_tax > 1000
  AND sm.sm_type = 'AIR'
  AND i.i_category = 'Electronics'
  AND i.i_brand IN ('BrandA', 'BrandB')
GROUP BY
    i.i_category,
    i.i_brand,
    sm.sm_carrier,
    date_trunc('month', date_parse(cast(cs.cs_sold_date_sk as varchar), '%Y%m%d'))
HAVING (COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0)) > 5000
ORDER BY total_net_profit DESC
LIMIT 50
