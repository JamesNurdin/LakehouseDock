WITH avg_price AS (
    SELECT avg(i_current_price) AS avg_item_price
    FROM item
),
store_sales_agg AS (
    SELECT
        s.s_state AS state,
        'store' AS sales_channel,
        SUM(ss.ss_net_paid) AS total_sales,
        (SELECT avg_item_price FROM avg_price) AS avg_item_price
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = ss.ss_promo_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY s.s_state
),
catalog_sales_agg AS (
    SELECT
        cc.cc_state AS state,
        'catalog' AS sales_channel,
        SUM(cs.cs_net_paid) AS total_sales,
        (SELECT avg_item_price FROM avg_price) AS avg_item_price
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = cs.cs_promo_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY cc.cc_state
)
SELECT state,
       sales_channel,
       total_sales,
       avg_item_price
FROM store_sales_agg
UNION ALL
SELECT state,
       sales_channel,
       total_sales,
       avg_item_price
FROM catalog_sales_agg
ORDER BY total_sales DESC
LIMIT 100
