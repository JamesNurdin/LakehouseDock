WITH base AS (
    SELECT
        d_sold.d_year AS d_year,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        wsite.web_site_id,
        wsite.web_state,
        sm.sm_type,
        cp.cp_department,
        ws.ws_net_profit,
        cr.cr_return_amount,
        sr.sr_return_amt
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    WHERE d_sold.d_year = 2000
      AND i.i_brand = 'BrandX'
      AND p.p_discount_active = 'Y'
      AND wsite.web_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Electronics'
)
SELECT DISTINCT
    d_year,
    i_item_id,
    i_brand,
    i_category,
    web_site_id,
    web_state,
    sm_type,
    cp_department,
    total_profit,
    total_return_amount,
    total_store_return_amount,
    profit_rank
FROM (
    SELECT
        d_year,
        i_item_id,
        i_brand,
        i_category,
        web_site_id,
        web_state,
        sm_type,
        cp_department,
        SUM(ws_net_profit) AS total_profit,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(sr_return_amt) AS total_store_return_amount,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM base
    GROUP BY
        d_year,
        i_item_id,
        i_brand,
        i_category,
        web_site_id,
        web_state,
        sm_type,
        cp_department
) t
WHERE profit_rank <= 10
ORDER BY d_year, profit_rank
