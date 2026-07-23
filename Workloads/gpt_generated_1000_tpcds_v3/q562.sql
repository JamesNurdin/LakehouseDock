SELECT
    cc.cc_name AS call_center_name,
    d.d_year,
    regexp_extract(i.i_product_name, '[0-9]+') AS product_number,
    concat('Item ', i.i_item_id, ': ', i.i_product_name) AS product_label,
    sum(cs.cs_net_paid) AS total_net_paid
FROM
    catalog_sales cs
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    regexp_like(i.i_product_name, '[A-Z]{3}[0-9]{2}')
    AND p.p_promo_name LIKE '%discount%'
    AND d.d_year = 2001
    AND substr(cp.cp_catalog_page_id, 1, 5) = 'AAAAA'
GROUP BY
    cc.cc_name,
    d.d_year,
    regexp_extract(i.i_product_name, '[0-9]+'),
    concat('Item ', i.i_item_id, ': ', i.i_product_name)
ORDER BY
    total_net_paid DESC
LIMIT 100
