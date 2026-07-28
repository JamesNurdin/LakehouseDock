WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        i.i_product_name,
        cs.cs_sold_date_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cs.cs_item_sk, i.i_product_name, cs.cs_sold_date_sk
)

SELECT
    sa.cs_item_sk,
    sa.i_product_name,
    sa.cs_sold_date_sk,
    sa.total_sales,
    sa.total_profit,
    CASE WHEN sa.avg_discount > 30 THEN 'High Discount' ELSE 'Low Discount' END AS discount_category,
    'Promotion' AS source,
    (
        SELECT MAX(p.p_cost)
        FROM promotion p
        WHERE p.p_item_sk = sa.cs_item_sk
    ) AS max_promo_cost
FROM sales_agg sa
WHERE sa.avg_discount > 30
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = sa.cs_item_sk
          AND p.p_discount_active = 'Y'
      )
UNION ALL
SELECT
    sa.cs_item_sk,
    sa.i_product_name,
    sa.cs_sold_date_sk,
    sa.total_sales,
    sa.total_profit,
    CASE WHEN cc.cc_market_manager IS NOT NULL THEN 'Target Market' ELSE 'Other Market' END AS discount_category,
    'CallCenter' AS source,
    NULL AS max_promo_cost
FROM sales_agg sa
JOIN catalog_sales cs ON cs.cs_item_sk = sa.cs_item_sk AND cs.cs_sold_date_sk = sa.cs_sold_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_mkt_desc = 'Reduced'
  AND sa.sales_rank = 1
LIMIT 100
