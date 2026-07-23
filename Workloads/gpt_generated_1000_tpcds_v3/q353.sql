SELECT
    sm.sm_carrier AS carrier,
    cp.cp_department AS department,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    COUNT(DISTINCT i.i_item_sk) AS distinct_item_count,
    COUNT(DISTINCT CONCAT(i.i_brand, '-', i.i_category)) AS distinct_brand_category_count,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS positive_profit_sum,
    SUM(
        (SELECT COALESCE(SUM(cr.cr_return_amount), 0)
         FROM catalog_returns cr
         WHERE cr.cr_order_number = cs.cs_order_number
           AND cr.cr_item_sk = cs.cs_item_sk)
    ) AS total_return_amount,
    CASE
        WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_profit) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_level,
    SUM(CASE WHEN regexp_like(i.i_item_desc, '^[A-Z]{2}[0-9]{3}') THEN 1 ELSE 0 END) AS matching_desc_item_count
FROM catalog_sales cs
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE sm.sm_contract LIKE '%a%'
  AND ca.ca_city LIKE 'A%'
  AND regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
GROUP BY sm.sm_carrier, cp.cp_department
HAVING SUM(cs.cs_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
