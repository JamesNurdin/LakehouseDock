WITH per_store AS (
    SELECT
        s.s_store_id,
        p.p_promo_id,
        t.t_meal_time,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS returns_amount,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS returns_loss
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_store_sk = s.s_store_sk
       AND sr.sr_return_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND s.s_number_employees > 200
      AND p.p_discount_active = 'Y'
      AND t.t_meal_time = 'lunch'
      AND ss.ss_quantity > 1
    GROUP BY s.s_store_id, p.p_promo_id, t.t_meal_time
),
promo_summary AS (
    SELECT
        p_promo_id,
        t_meal_time,
        SUM(store_sales_amount) AS total_sales,
        SUM(store_profit) AS total_profit,
        SUM(returns_amount) AS total_returns,
        SUM(returns_loss) AS total_return_loss,
        COUNT(DISTINCT s_store_id) AS store_count,
        AVG(store_sales_amount) AS avg_sales_per_store
    FROM per_store
    GROUP BY p_promo_id, t_meal_time
),
catalog_agg AS (
    SELECT
        p.p_promo_id AS p_promo_id,
        t.t_meal_time AS t_meal_time,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_date_sk = t.t_time_sk
    WHERE p.p_discount_active = 'Y'
      AND t.t_meal_time = 'lunch'
      AND cs.cs_quantity > 1
    GROUP BY p.p_promo_id, t.t_meal_time
)
SELECT
    ps.p_promo_id,
    ps.t_meal_time,
    ps.total_sales,
    ps.total_profit,
    ps.total_returns,
    ps.total_return_loss,
    ca.catalog_sales_amount,
    ca.catalog_profit,
    (ps.total_profit - ps.total_return_loss + COALESCE(ca.catalog_profit, 0)) / NULLIF(ps.total_sales + COALESCE(ca.catalog_sales_amount, 0), 0) AS overall_profit_margin,
    ps.avg_sales_per_store
FROM promo_summary ps
LEFT JOIN catalog_agg ca
    ON ps.p_promo_id = ca.p_promo_id
   AND ps.t_meal_time = ca.t_meal_time
WHERE ps.total_sales > 20000
  AND (ca.catalog_sales_amount IS NULL OR ca.catalog_sales_amount > 5000)
ORDER BY overall_profit_margin DESC, ps.total_sales DESC
LIMIT 100
