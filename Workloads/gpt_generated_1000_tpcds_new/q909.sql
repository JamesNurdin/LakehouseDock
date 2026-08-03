WITH sampled_pages AS (
        SELECT *
        FROM catalog_page TABLESAMPLE BERNOULLI (10)
    ),
    catalog_full AS (
        SELECT *
        FROM catalog_returns cr
        FULL OUTER JOIN catalog_sales cs
            ON cr.cr_order_number = cs.cs_order_number
    ),
    joined_all AS (
        SELECT
            cf.cr_return_amount,
            cf.cs_net_paid,
            d.d_year,
            d.d_month_seq,
            sm.sm_type,
            p.p_promo_name,
            cc.cc_city,
            ws.ws_net_paid AS ws_net_paid,
            ss.ss_net_paid AS ss_net_paid,
            w.w_warehouse_name,
            cu.c_customer_sk,
            ws_site.web_state,
            unnest_hours.hour AS hour_token,
            sp.cp_department,
            t.t_hour
        FROM catalog_full cf
        LEFT JOIN sampled_pages sp
            ON cf.cs_catalog_page_sk = sp.cp_catalog_page_sk
        LEFT JOIN date_dim d
            ON COALESCE(cf.cr_returned_date_sk, cf.cs_sold_date_sk) = d.d_date_sk
        LEFT JOIN time_dim t
            ON COALESCE(cf.cr_returned_time_sk, cf.cs_sold_time_sk) = t.t_time_sk
        LEFT JOIN ship_mode sm
            ON COALESCE(cf.cr_ship_mode_sk, cf.cs_ship_mode_sk) = sm.sm_ship_mode_sk
        LEFT JOIN promotion p
            ON cf.cs_promo_sk = p.p_promo_sk
        LEFT JOIN call_center cc
            ON COALESCE(cf.cr_call_center_sk, cf.cs_call_center_sk) = cc.cc_call_center_sk
        LEFT JOIN warehouse w
            ON COALESCE(cf.cr_warehouse_sk, cf.cs_warehouse_sk) = w.w_warehouse_sk
        LEFT JOIN store_sales ss
            ON cf.cs_sold_date_sk = ss.ss_sold_date_sk
               AND cf.cs_sold_time_sk = ss.ss_sold_time_sk
        LEFT JOIN web_sales ws
            ON cf.cs_sold_date_sk = ws.ws_sold_date_sk
               AND cf.cs_sold_time_sk = ws.ws_sold_time_sk
        LEFT JOIN customer cu
            ON cf.cs_bill_customer_sk = cu.c_customer_sk
        LEFT JOIN web_site ws_site
            ON ws.ws_web_site_sk = ws_site.web_site_sk
        LEFT JOIN LATERAL (
                SELECT hour
                FROM UNNEST(split(cc.cc_hours, ',')) AS t(hour)
            ) AS unnest_hours ON true
        WHERE cc.cc_city = 'Pleasant Grove'
          AND sm.sm_type = 'OVERNIGHT'
          AND p.p_discount_active = 'Y'
          AND d.d_year = 2001
          AND ws_site.web_state = 'CA'
          AND cu.c_preferred_cust_flag = 'Y'
    ),
    cube_agg AS (
        SELECT
            d_year,
            sm_type,
            p_promo_name,
            cc_city,
            SUM(cs_net_paid) AS total_sales,
            COUNT(DISTINCT c_customer_sk) AS unique_customers,
            AVG(ws_net_paid) AS avg_web_paid,
            SUM(ss_net_paid) AS total_store_paid
        FROM joined_all
        GROUP BY CUBE (d_year, sm_type, p_promo_name, cc_city)
    )
SELECT
    d_year,
    sm_type,
    p_promo_name,
    cc_city,
    total_sales,
    unique_customers,
    avg_web_paid,
    total_store_paid
FROM cube_agg
WHERE total_sales > 100000
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
