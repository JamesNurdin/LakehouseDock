WITH base AS (
    SELECT
        d_date,
        d_year,
        t_hour,
        t_shift,
        ss_quantity,
        ws_quantity,
        ss_net_profit,
        ws_net_profit,
        (ss_net_profit + ws_net_profit) AS combined_net_profit,
        promotion.p_promo_name AS promo_name,
        call_center.cc_name AS call_center_name,
        catalog_page.cp_department AS catalog_department,
        web_site.web_name AS site_name,
        ship_mode.sm_type AS ship_type
    FROM store_sales
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
    JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN call_center ON call_center.cc_closed_date_sk = date_dim.d_date_sk
    JOIN catalog_page ON catalog_page.cp_start_date_sk = date_dim.d_date_sk
    JOIN web_site ON web_site.web_open_date_sk = date_dim.d_date_sk
    JOIN web_sales ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN ship_mode ON ship_mode.sm_ship_mode_sk = web_sales.ws_ship_mode_sk
    WHERE d_year = 2001
      AND t_shift = 'second'
      AND cc_division IN (1, 3, 6)
      AND cp_catalog_number BETWEEN 1 AND 5
      AND p_discount_active = 'Y'
      AND sm_type = 'Air'
      AND ss_quantity > 1
      AND ws_quantity > 0
)
SELECT
    d_date,
    d_year,
    t_hour,
    t_shift,
    ss_quantity,
    ws_quantity,
    promo_name,
    call_center_name,
    catalog_department,
    site_name,
    ship_type,
    combined_net_profit,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY combined_net_profit DESC) AS profit_rank_by_date
FROM base
ORDER BY profit_rank_by_date, d_date
LIMIT 100
