WITH sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS units_sold,
        CAST(NULL AS decimal(7,2)) AS total_returns,
        CAST(NULL AS integer) AS units_returned,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY i.i_item_id, i.i_product_name
),
returns AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        CAST(NULL AS decimal(7,2)) AS total_sales,
        CAST(NULL AS integer) AS units_sold,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(sr.sr_return_quantity) AS units_returned,
        'store' AS channel
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'California'
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT *
FROM sales
UNION ALL
SELECT *
FROM returns
ORDER BY total_sales DESC NULLS LAST, total_returns DESC NULLS LAST
LIMIT 100
