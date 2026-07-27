WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        'Sale' AS record_type,
        SUM(cs.cs_net_profit) AS total_amount,
        (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_start.d_current_year = 'Y'
      AND d_end.d_current_year = 'Y'
      AND p.p_discount_active = 'Y'
      AND cs.cs_item_sk IN (SELECT p2.p_item_sk FROM promotion p2 WHERE p2.p_channel_email = 'Y')
    GROUP BY d.d_year
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        'Return' AS record_type,
        SUM(cr.cr_return_amount) AS total_amount,
        (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS avg_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cr.cr_return_tax > 0
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY d.d_year
)
SELECT year,
       record_type,
       total_amount,
       avg_amount
FROM sales_agg
UNION ALL
SELECT year,
       record_type,
       total_amount,
       avg_amount
FROM returns_agg
ORDER BY year DESC, record_type
LIMIT 100
