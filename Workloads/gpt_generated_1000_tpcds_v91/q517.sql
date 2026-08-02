WITH sales_agg AS (
    SELECT
        i.i_category,
        cc.cc_state,
        p.p_channel_event,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        CASE WHEN SUM(cs.cs_ext_discount_amt) > 0 THEN 'Discounted' ELSE 'Full Price' END AS discount_type,
        MIN(CONCAT(i.i_brand, ':', i.i_product_name)) AS sample_brand_product,
        MIN(regexp_extract(i.i_product_name, '(\\w+)', 1)) AS first_word,
        MIN(substr(i.i_product_name, 1, 5)) AS product_prefix,
        MIN(CASE WHEN cc.cc_name LIKE 'A%' THEN 'StartsWithA' ELSE 'Other' END) AS cc_name_category
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_start_date < DATE '2001-01-01'
      AND regexp_like(p.p_promo_name, '(?i)discount')
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_channel_event = 'N'
      )
    GROUP BY CUBE (i.i_category, cc.cc_state, p.p_channel_event)
)
SELECT
    s.i_category,
    s.cc_state,
    s.p_channel_event,
    s.total_sales,
    s.total_quantity,
    s.total_discount,
    s.discount_type,
    s.sample_brand_product,
    s.first_word,
    s.product_prefix,
    s.cc_name_category,
    s.total_sales / (SELECT AVG(total_sales) FROM sales_agg) AS sales_vs_avg,
    RANK() OVER (PARTITION BY s.cc_state ORDER BY s.total_sales DESC) AS sales_rank_state
FROM sales_agg s
ORDER BY s.total_sales DESC
LIMIT 100
