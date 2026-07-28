WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_tax,
        cs.cs_quantity,
        i.i_item_desc,
        i.i_brand,
        i.i_product_name,
        p.p_promo_name,
        cp.cp_type,
        cc.cc_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2,}[0-9]{3}')
      AND p.p_promo_name LIKE '%Clearance%'
      AND cp.cp_type = 'monthly'
),
agg_sales AS (
    SELECT
        i_brand,
        p_promo_name,
        i_product_name,
        i_item_desc,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        SUM(cs_net_paid) AS total_net_paid,
        AVG(cs_net_paid_inc_tax) AS avg_net_paid_inc_tax
    FROM filtered_sales
    GROUP BY i_brand, p_promo_name, i_product_name, i_item_desc
    HAVING SUM(cs_net_paid) > 10000
)
SELECT
    a.i_brand,
    a.p_promo_name,
    a.distinct_orders,
    a.total_net_paid,
    a.avg_net_paid_inc_tax,
    (SELECT AVG(cs2.cs_net_paid) FROM catalog_sales cs2) AS overall_avg_net_paid,
    ROW_NUMBER() OVER (ORDER BY a.total_net_paid DESC) AS brand_rank,
    CONCAT(a.i_brand, ' - ', a.i_product_name) AS brand_product_concat,
    SUBSTRING(a.i_item_desc FROM 1 FOR 10) AS short_desc
FROM agg_sales a
ORDER BY a.total_net_paid DESC
LIMIT 100
