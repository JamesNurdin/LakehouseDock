WITH sales_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
)
SELECT DISTINCT
    promo_name,
    ship_type,
    hour_of_day,
    site_name,
    total_sales,
    total_profit,
    orders
FROM (
    SELECT
        pr1.p_promo_name AS promo_name,
        sm1.sm_type      AS ship_type,
        td1.t_hour       AS hour_of_day,
        ws1.web_name     AS site_name,
        SUM(sales_base.ws_ext_sales_price) AS total_sales,
        SUM(sales_base.ws_net_profit)      AS total_profit,
        COUNT(DISTINCT sales_base.ws_order_number) AS orders
    FROM sales_base
        JOIN promotion   pr1 ON sales_base.ws_promo_sk = pr1.p_promo_sk
        JOIN ship_mode   sm1 ON sales_base.ws_ship_mode_sk = sm1.sm_ship_mode_sk
        JOIN time_dim    td1 ON sales_base.ws_sold_time_sk = td1.t_time_sk
        JOIN web_site    ws1 ON sales_base.ws_web_site_sk = ws1.web_site_sk
        JOIN promotion   pr2 ON sales_base.ws_promo_sk = pr2.p_promo_sk
        JOIN ship_mode   sm2 ON sales_base.ws_ship_mode_sk = sm2.sm_ship_mode_sk
        JOIN time_dim    td2 ON sales_base.ws_sold_time_sk = td2.t_time_sk
        JOIN web_site    ws2 ON sales_base.ws_web_site_sk = ws2.web_site_sk
        JOIN ship_mode   sm3 ON sales_base.ws_ship_mode_sk = sm3.sm_ship_mode_sk
    WHERE pr1.p_purpose = 'Discount'
      AND EXISTS (
          SELECT 1
          FROM promotion p_check
          WHERE p_check.p_response_target > 100
            AND p_check.p_promo_sk = pr1.p_promo_sk
      )
    GROUP BY GROUPING SETS (
        (pr1.p_promo_name, sm1.sm_type, td1.t_hour, ws1.web_name),
        (pr1.p_promo_name, sm1.sm_type, td1.t_hour),
        (pr1.p_promo_name, sm1.sm_type),
        (pr1.p_promo_name),
        ()
    )
    UNION ALL
    SELECT
        pr1.p_promo_name AS promo_name,
        sm1.sm_type      AS ship_type,
        td1.t_hour       AS hour_of_day,
        ws1.web_name     AS site_name,
        SUM(sales_base.ws_ext_sales_price) AS total_sales,
        SUM(sales_base.ws_net_profit)      AS total_profit,
        COUNT(DISTINCT sales_base.ws_order_number) AS orders
    FROM sales_base
        JOIN promotion   pr1 ON sales_base.ws_promo_sk = pr1.p_promo_sk
        JOIN ship_mode   sm1 ON sales_base.ws_ship_mode_sk = sm1.sm_ship_mode_sk
        JOIN time_dim    td1 ON sales_base.ws_sold_time_sk = td1.t_time_sk
        JOIN web_site    ws1 ON sales_base.ws_web_site_sk = ws1.web_site_sk
        JOIN promotion   pr2 ON sales_base.ws_promo_sk = pr2.p_promo_sk
        JOIN ship_mode   sm2 ON sales_base.ws_ship_mode_sk = sm2.sm_ship_mode_sk
        JOIN time_dim    td2 ON sales_base.ws_sold_time_sk = td2.t_time_sk
        JOIN web_site    ws2 ON sales_base.ws_web_site_sk = ws2.web_site_sk
        JOIN ship_mode   sm3 ON sales_base.ws_ship_mode_sk = sm3.sm_ship_mode_sk
    WHERE pr1.p_channel_tv = 'Y'
      AND EXISTS (
          SELECT 1
          FROM promotion p_check
          WHERE p_check.p_response_target < 50
            AND p_check.p_promo_sk = pr1.p_promo_sk
      )
    GROUP BY GROUPING SETS (
        (pr1.p_promo_name, sm1.sm_type, td1.t_hour, ws1.web_name),
        (pr1.p_promo_name, sm1.sm_type, td1.t_hour),
        (pr1.p_promo_name, sm1.sm_type),
        (pr1.p_promo_name),
        ()
    )
) AS agg
ORDER BY total_sales DESC
LIMIT 100
