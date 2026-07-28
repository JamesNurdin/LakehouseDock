WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_state,
        i.i_brand,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_paid) AS avg_net_paid,
        COUNT(*) AS cnt_sales,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank_by_center
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
        AND i.i_brand = 'BrandX'                -- keep outer join, filter brand in ON clause
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND hd.hd_dep_count >= 3
      AND cs.cs_ext_list_price > 5000
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
    GROUP BY ROLLUP (cc.cc_state, i.i_brand, cc.cc_call_center_sk)
)
SELECT
    sa.cc_state,
    COALESCE(sa.i_brand, 'UNKNOWN') AS brand,
    sa.total_sales,
    sa.avg_net_paid,
    CASE
        WHEN sa.total_sales > (SELECT AVG(cs.cs_ext_sales_price) FROM catalog_sales cs) THEN 'High'
        ELSE 'Low'
    END AS sales_level,
    sa.sales_rank_by_center
FROM sales_agg sa
WHERE sa.cnt_sales > 0
ORDER BY sa.total_sales DESC
LIMIT 100
