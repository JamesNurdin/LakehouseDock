WITH sales_joined AS (
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_list_price,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cc.cc_state,
        cp.cp_department,
        i.i_category,
        i.i_size,
        i.i_brand,
        p.p_discount_active,
        d.d_year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_list_price > 80
      AND cs.cs_quantity BETWEEN 1 AND 20
      AND i.i_size = 'extra large'
      AND cc.cc_state = 'CA'
      AND d.d_year = 2001
      AND p.p_discount_active = 'Y'
)
SELECT 
    d_year,
    cc_state,
    i_category,
    order_type,
    SUM(cs_net_paid) AS total_net_paid,
    COUNT(*) AS order_count,
    AVG(cs_list_price) AS avg_list_price,
    MIN(cs_list_price) AS min_price,
    MAX(cs_list_price) AS max_price
FROM (
    SELECT 
        d_year,
        cc_state,
        i_category,
        CASE WHEN cs_quantity > 10 THEN 'Bulk' ELSE 'Regular' END AS order_type,
        cs_net_paid,
        cs_list_price,
        cs_quantity
    FROM sales_joined
) t
GROUP BY ROLLUP (d_year, cc_state, i_category, order_type)
HAVING SUM(cs_net_paid) > 1000
UNION DISTINCT
SELECT 
    d_year,
    cc_state,
    i_category,
    order_type,
    SUM(cs_net_paid) AS total_net_paid,
    COUNT(*) AS order_count,
    AVG(cs_list_price) AS avg_list_price,
    MIN(cs_list_price) AS min_price,
    MAX(cs_list_price) AS max_price
FROM (
    SELECT 
        d_year,
        cc_state,
        i_category,
        CASE WHEN cs_quantity > 10 THEN 'Bulk' ELSE 'Regular' END AS order_type,
        cs_net_paid,
        cs_list_price,
        cs_quantity
    FROM sales_joined
    WHERE cs_ext_discount_amt > 5
) t2
GROUP BY ROLLUP (d_year, cc_state, i_category, order_type)
HAVING SUM(cs_net_paid) > 1000
ORDER BY d_year ASC, cc_state ASC, i_category ASC, order_type ASC
LIMIT 100
