SELECT
    s.s_store_name,
    cp.cp_department,
    CASE WHEN cs.cs_quantity > 10 THEN 'Large' ELSE 'Small' END AS order_size_category,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(COALESCE(ss.ss_net_profit, 0)) AS avg_store_profit,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    MIN(cs.cs_sold_date_sk) AS first_sold_date_sk,
    (SELECT AVG(p3.p_cost) FROM promotion p3 WHERE p3.p_channel_radio = 'N') AS avg_radio_promo_cost
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_market_id IN (1, 4, 7)
  AND p.p_channel_radio = 'N'
  AND ca_bill.ca_gmt_offset = -5.00
  AND cp.cp_catalog_number = 2
GROUP BY
    s.s_store_name,
    cp.cp_department,
    CASE WHEN cs.cs_quantity > 10 THEN 'Large' ELSE 'Small' END
ORDER BY total_net_paid DESC
LIMIT 100
