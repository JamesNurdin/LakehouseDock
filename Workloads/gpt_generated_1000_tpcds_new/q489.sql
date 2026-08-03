WITH
    -- Sample a portion of call_center and reuse it under a different alias
    cc_sample AS (
        SELECT *
        FROM call_center
        TABLESAMPLE BERNOULLI (5)
    ),
    cc_alias AS (
        SELECT cc_call_center_sk, cc_state, cc_country
        FROM call_center
    ),
    -- Store sales joined to its dimensions
    ss_join AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_net_paid,
            d.d_year,
            s.s_store_name,
            cd.cd_gender,
            hd.hd_income_band_sk
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    ),
    -- Catalog returns joined to its dimensions (reuse customer & household dims under different aliases)
    cr_join AS (
        SELECT
            cr.cr_order_number,
            cr.cr_net_loss,
            d.d_year,
            w.w_warehouse_name,
            r.r_reason_desc,
            cc.cc_state,
            cc.cc_country,
            cd_ret.cd_gender AS ret_gender,
            hd_ret.hd_income_band_sk AS ret_income_band
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN cc_alias cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
        JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    ),
    -- Web page and web site joined through the same date dimension (used twice)
    wp_ws_join AS (
        SELECT
            wp.wp_web_page_id,
            ws.web_site_id,
            d.d_year,
            wp.wp_type,
            ws.web_market_manager,
            ARRAY[wp.wp_type, ws.web_market_manager] AS combined_arr
        FROM web_page wp
        JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
        JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    ),
    -- Expand the array with UNNEST
    unnested_wp AS (
        SELECT
            wp_web_page_id,
            web_site_id,
            d_year,
            element
        FROM wp_ws_join
        CROSS JOIN UNNEST(combined_arr) AS t(element)
    ),
    -- Union of sales and returns (distinct) to force de‑duplication
    union_sales_returns AS (
        SELECT d_year,
               s_store_name,
               NULL AS r_reason_desc,
               ss_net_paid      AS net_amount,
               0                AS net_loss
        FROM ss_join
        UNION
        SELECT d_year,
               NULL AS s_store_name,
               r_reason_desc,
               0                AS net_amount,
               cr_net_loss      AS net_loss
        FROM cr_join
    ),
    -- Aggregate with CUBE and CASE expression
    agg_cube AS (
        SELECT
            d_year,
            s_store_name,
            CASE WHEN r_reason_desc IS NULL THEN 'No Reason' ELSE r_reason_desc END AS reason_category,
            SUM(net_amount) AS total_sales,
            SUM(net_loss)   AS total_returns
        FROM union_sales_returns
        GROUP BY CUBE (d_year, s_store_name, r_reason_desc)
    ),
    -- Intersect the year set from the cube with years present in the web data
    intersect_years AS (
        SELECT d_year
        FROM agg_cube
        INTERSECT
        SELECT DISTINCT d_year FROM unnested_wp
    ),
    -- Final result after intersecting and keeping unmatched rows from warehouse via FULL OUTER JOIN
    final_result AS (
        SELECT
            a.d_year,
            a.s_store_name,
            a.reason_category,
            a.total_sales,
            a.total_returns,
            w.w_warehouse_name,
            w.w_city
        FROM agg_cube a
        JOIN intersect_years i ON a.d_year = i.d_year
        FULL OUTER JOIN warehouse w ON 1 = 1
    )
SELECT *
FROM final_result
ORDER BY d_year DESC, s_store_name
LIMIT 100
