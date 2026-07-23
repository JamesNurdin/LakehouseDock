WITH distinct_promos AS (
    SELECT DISTINCT p.p_promo_sk, p.p_promo_name, p.p_item_sk
    FROM promotion p
    WHERE p.p_channel_catalog = 'N'
)
SELECT
    cc.cc_name,
    i.i_category,
    dp.p_promo_name,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    AVG(cs.cs_ext_tax) AS avg_tax,
    MIN(cs.cs_net_profit) AS min_profit,
    MAX(cs.cs_net_profit) AS max_profit
FROM call_center cc
JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN distinct_promos dp ON cs.cs_promo_sk = dp.p_promo_sk AND dp.p_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
WHERE
    cc.cc_state = 'CA'
    AND cc.cc_gmt_offset >= -8.00
    AND cs.cs_sold_date_sk BETWEEN 2450820 AND 2450830
    AND i.i_brand_id = 5
    AND sr.sr_net_loss > 100.00
    AND cs.cs_ext_tax > 20.00
GROUP BY
    cc.cc_name,
    i.i_category,
    dp.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
