WITH filtered_items AS (
    SELECT i_item_sk
    FROM item
    WHERE regexp_like(i_item_desc, '\\d{3}')
)
SELECT
    cc.cc_name,
    cc.cc_city,
    CONCAT(cc.cc_name, ' - ', cc.cc_city) AS center_full,
    CASE WHEN regexp_like(p.p_promo_name, '(?i)discount') THEN 'Discount' ELSE 'Other' END AS promo_category,
    COUNT(cs.cs_order_number) AS sales_cnt,
    SUM(cs.cs_net_profit) AS total_profit
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE
    cc.cc_name LIKE 'A%'
    AND regexp_like(p.p_promo_name, '(?i)discount')
    AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND cs.cs_item_sk IN (SELECT i_item_sk FROM filtered_items)
GROUP BY
    cc.cc_name,
    cc.cc_city,
    CASE WHEN regexp_like(p.p_promo_name, '(?i)discount') THEN 'Discount' ELSE 'Other' END,
    CONCAT(cc.cc_name, ' - ', cc.cc_city)
ORDER BY total_profit DESC
LIMIT 100
