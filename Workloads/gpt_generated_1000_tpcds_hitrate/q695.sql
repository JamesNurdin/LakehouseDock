WITH promo_filtered AS (
    SELECT p_promo_sk, p_end_date_sk
    FROM promotion
    WHERE p_end_date_sk > 2450300
)
SELECT *
FROM (
    SELECT
        td.t_hour AS hour_of_day,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_profit,
        CASE WHEN AVG(ss.ss_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        'store' AS sales_channel
    FROM store_sales ss
    RIGHT OUTER JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
        AND ss.ss_store_sk NOT IN (SELECT ss_store_sk FROM store_sales WHERE ss_quantity = 0)
    LEFT JOIN promo_filtered pf
        ON ss.ss_promo_sk = pf.p_promo_sk
    WHERE
        pf.p_promo_sk IS NOT NULL
        AND td.t_hour NOT IN (SELECT t_hour FROM time_dim WHERE t_meal_time = 'Breakfast')
    GROUP BY td.t_hour

    UNION ALL

    SELECT
        td.t_hour AS hour_of_day,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        CASE WHEN AVG(ws.ws_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        'web' AS sales_channel
    FROM web_sales ws
    RIGHT OUTER JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        EXISTS (SELECT 1 FROM promotion p2 WHERE p2.p_promo_sk = ws.ws_promo_sk AND p2.p_discount_active = 'Y')
        AND td.t_hour NOT IN (SELECT t_hour FROM time_dim WHERE t_meal_time = 'Breakfast')
    GROUP BY td.t_hour
) combined
ORDER BY profit_category DESC, hour_of_day
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
