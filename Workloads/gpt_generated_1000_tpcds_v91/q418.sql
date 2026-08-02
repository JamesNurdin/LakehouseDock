WITH base AS (
    SELECT
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        p.p_promo_name AS promo_name,
        p.p_discount_active AS discount_active,
        p.p_channel_tv AS channel_tv,
        sm.sm_type AS ship_mode_type,
        ca.ca_city AS city,
        td.t_meal_time AS meal_time,
        ws_site.web_state AS web_state
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE p.p_discount_active = 'Y'
      AND td.t_meal_time = 'dinner'
      AND ws_site.web_state = 'CA'
),
agg AS (
    SELECT
        promo_name,
        ship_mode_type,
        SUM(cs_net_profit + ws_net_profit) AS total_net_profit,
        SUM(cs_ext_sales_price + ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT city) AS distinct_cities,
        GROUPING(promo_name) AS g_promo,
        GROUPING(ship_mode_type) AS g_mode
    FROM base
    GROUP BY ROLLUP(promo_name, ship_mode_type)
)
SELECT DISTINCT
    COALESCE(promo_name, 'All Promotions') AS promotion,
    COALESCE(ship_mode_type, 'All Ship Modes') AS ship_mode,
    total_net_profit,
    total_sales,
    distinct_cities,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
OFFSET 0 LIMIT 100
