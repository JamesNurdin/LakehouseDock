WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_category = 'Sports'
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
    GROUP BY cs.cs_sold_date_sk, i.i_category
),
returns_data AS (
    SELECT
        cr.cr_returned_date_sk AS sold_date_sk,
        i.i_category AS category,
        -SUM(cr.cr_return_amount) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_category = 'Sports'
      AND sm.sm_type = 'AIR'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY cr.cr_returned_date_sk, i.i_category
),
combined AS (
    SELECT DISTINCT sold_date_sk, category, total_profit, sales_cnt
    FROM sales_data
    UNION ALL
    SELECT DISTINCT sold_date_sk, category, total_profit, sales_cnt
    FROM returns_data
)
SELECT DISTINCT
    c.sold_date_sk,
    c.category,
    c.total_profit,
    c.sales_cnt
FROM combined c
WHERE c.total_profit > (
    SELECT AVG(cs.cs_net_profit)
    FROM catalog_sales cs
)
ORDER BY c.sold_date_sk DESC, c.category ASC
OFFSET 0
LIMIT 100
