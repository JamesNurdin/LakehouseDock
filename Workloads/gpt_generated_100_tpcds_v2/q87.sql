SELECT
    cc.cc_call_center_id,
    concat(cc.cc_city, ', ', cc.cc_state) AS call_center_location,
    p.p_promo_name,
    sum(cs.cs_net_profit) AS total_net_profit,
    count(*) AS sales_count,
    max(length(cc.cc_name)) AS call_center_name_len
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE cc.cc_state LIKE 'N%'
  AND lower(p.p_promo_name) LIKE '%discount%'
  AND d.d_year = 2002
GROUP BY cc.cc_call_center_id, concat(cc.cc_city, ', ', cc.cc_state), p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 10
