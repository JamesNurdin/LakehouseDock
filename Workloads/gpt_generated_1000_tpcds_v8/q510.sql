WITH sales_union AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_sold_time_sk AS sold_time_sk,
        cs.cs_net_paid_inc_tax AS net_paid,
        cp.cp_department AS department,
        sm.sm_type AS ship_type,
        p.p_promo_name AS promo_name,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        t.t_hour AS sale_hour
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
      AND cs.cs_net_paid_inc_tax > 500
      AND sm.sm_code IN ('AIR', 'SEA')
      AND p.p_channel_email = 'Y'
      AND t.t_hour BETWEEN 9 AND 17

    UNION DISTINCT

    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_sold_time_sk AS sold_time_sk,
        ws.ws_net_paid_inc_tax AS net_paid,
        CAST(NULL AS varchar) AS department,
        sm2.sm_type AS ship_type,
        p2.p_promo_name AS promo_name,
        CASE WHEN p2.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        t2.t_hour AS sale_hour
    FROM web_sales ws
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
      AND ws.ws_net_paid_inc_tax > 500
      AND sm2.sm_code IN ('AIR', 'SEA')
      AND p2.p_channel_email = 'Y'
      AND t2.t_hour BETWEEN 9 AND 17
),

intersect_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
    INTERSECT
    SELECT ws.ws_order_number AS order_number
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
),

final_agg AS (
    SELECT
        su.department,
        su.ship_type,
        SUM(su.net_paid) AS total_net_paid,
        COUNT(DISTINCT su.order_number) AS distinct_orders,
        CASE WHEN SUM(su.net_paid) > 10000 THEN 'High' ELSE 'Medium' END AS revenue_category,
        RANK() OVER (PARTITION BY su.department ORDER BY SUM(su.net_paid) DESC) AS dept_rank
    FROM sales_union su
    WHERE su.order_number IN (SELECT order_number FROM intersect_orders)
      AND NOT EXISTS (
          SELECT 1 FROM catalog_returns cr
          WHERE cr.cr_order_number = su.order_number
      )
    GROUP BY GROUPING SETS (
        (su.department, su.ship_type),
        (su.department),
        (su.ship_type),
        ()
    )
    HAVING SUM(su.net_paid) > 2000
)
SELECT
    department,
    ship_type,
    total_net_paid,
    distinct_orders,
    revenue_category,
    dept_rank
FROM final_agg
ORDER BY total_net_paid DESC
LIMIT 100
