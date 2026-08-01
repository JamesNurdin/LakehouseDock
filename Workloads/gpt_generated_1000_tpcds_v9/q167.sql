WITH filtered_catalog AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cc.cc_name,
        cp.cp_description,
        p.p_promo_name,
        p.p_channel_catalog,
        d.d_year,
        regexp_extract(p.p_promo_name, '\\d+', 0) AS promo_number,
        concat(cc.cc_name, ' - ', p.p_promo_name) AS label
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(cc.cc_name, '^Call Center[ A-Z0-9]*$')
      AND cp.cp_description LIKE '%special%discount%'
      AND p.p_channel_catalog = 'Y'
      AND d.d_year = 2001
)
SELECT
    cc_name,
    p_promo_name,
    promo_number,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    label
FROM filtered_catalog
GROUP BY
    cc_name,
    p_promo_name,
    promo_number,
    label
ORDER BY total_profit DESC
LIMIT 100
