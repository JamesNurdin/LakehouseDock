WITH filtered_sales AS (
    SELECT cs.cs_sold_date_sk,
           cs.cs_ship_date_sk,
           cs.cs_promo_sk,
           cs.cs_quantity,
           cs.cs_net_paid_inc_tax,
           cs.cs_net_profit,
           cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_tax > 5000
      AND cs.cs_quantity >= 2
)
SELECT p.p_promo_name,
       dd_sold.d_year,
       dd_sold.d_month_seq,
       COUNT(*) AS order_count,
       SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
       AVG(cs.cs_net_paid_inc_tax) AS avg_net_paid,
       MIN(cs.cs_net_paid_inc_tax) AS min_net_paid,
       MAX(cs.cs_net_paid_inc_tax) AS max_net_paid,
       (SELECT AVG(cs3.cs_net_paid_inc_tax) FROM catalog_sales cs3) AS overall_avg_net_paid
FROM filtered_sales cs
JOIN date_dim dd_sold ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim dd_start ON p.p_start_date_sk = dd_start.d_date_sk
JOIN date_dim dd_end ON p.p_end_date_sk = dd_end.d_date_sk
WHERE p.p_channel_press = 'N'
  AND p.p_channel_catalog = 'N'
  AND dd_sold.d_current_quarter = 'Y'
  AND EXISTS (
      SELECT 1
      FROM catalog_sales cs2
      WHERE cs2.cs_promo_sk = p.p_promo_sk
        AND cs2.cs_quantity > 5
  )
GROUP BY p.p_promo_name, dd_sold.d_year, dd_sold.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
