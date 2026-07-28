WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_state,
        i.i_brand,
        i.i_brand_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_state IN ('PA', 'GA', 'WA')
      AND cc.cc_manager = 'Wayne Ray'
      AND i.i_brand_id IN (8015002, 2002002)
      AND EXISTS (
          SELECT 1
          FROM item i2
          WHERE i2.i_item_sk = cs.cs_item_sk
            AND i2.i_units = 'Gross'
            AND i2.i_item_id = 'AAAAAAAABAAAAAAA'
      )
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_state,
        i.i_brand,
        i.i_brand_id
)
SELECT
    s.cc_state AS state,
    AVG(s.total_sales) AS avg_sales,
    SUM(s.total_profit) AS state_total_profit,
    COUNT(*) AS num_call_centers
FROM sales_agg s
GROUP BY s.cc_state
HAVING AVG(s.total_sales) > 10000
ORDER BY avg_sales DESC
LIMIT 100
