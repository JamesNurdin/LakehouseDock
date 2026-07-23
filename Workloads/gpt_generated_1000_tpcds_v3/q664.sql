WITH filtered_sales AS (
    SELECT
        cs.cs_net_paid AS net_paid,
        cs.cs_quantity AS quantity,
        d.d_year AS sale_year,
        cc.cc_city AS city,
        cc.cc_state AS state,
        cc.cc_country AS country,
        p.p_promo_name AS promo_name,
        regexp_extract(p.p_promo_name, '([0-9]+)', 1) AS promo_code,
        concat(cc.cc_state, '-', cc.cc_country) AS region,
        substring(w.w_warehouse_name, 1, 10) AS wh_prefix
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND regexp_like(cc.cc_city, '^[A-Z][a-z]+$')
      AND p.p_promo_name LIKE '%Discount%'
)
SELECT
    city,
    region,
    promo_name,
    promo_code,
    wh_prefix,
    sale_year,
    SUM(net_paid) AS total_net_paid,
    SUM(quantity) AS total_quantity,
    COUNT(*) AS num_sales
FROM filtered_sales
GROUP BY
    city,
    region,
    promo_name,
    promo_code,
    wh_prefix,
    sale_year
ORDER BY total_net_paid DESC
LIMIT 100
