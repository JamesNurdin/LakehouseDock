WITH sales_agg AS (
    SELECT
        d_sold.d_date,
        d_sold.d_year,
        sm.sm_type,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    WHERE d_sold.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 18
      AND ws.ws_ext_tax > 10
      AND (sm.sm_type = 'AIR' OR sm.sm_type IS NULL)
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY d_sold.d_date,
             d_sold.d_year,
             sm.sm_type,
             COALESCE(p.p_promo_name, 'No Promo')
    HAVING SUM(ws.ws_net_profit) > 1000
       AND COUNT(*) >= 10
)
SELECT
    d_date,
    d_year,
    sm_type,
    promo_name,
    total_profit,
    total_sales,
    order_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_year
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
