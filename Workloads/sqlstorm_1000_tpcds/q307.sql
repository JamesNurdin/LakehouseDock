SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    cp.cp_type,
    p.p_channel_tv,
    cc.cc_name,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(COALESCE(cr.cr_return_amount, 0.0)) AS total_returns,
    SUM(cs.cs_net_paid) - SUM(COALESCE(cr.cr_return_amount, 0.0)) AS net_revenue,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    AVG(cs.cs_quantity) AS avg_quantity
FROM catalog_sales cs
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, cp.cp_type, p.p_channel_tv, cc.cc_name
ORDER BY net_revenue DESC
LIMIT 100
