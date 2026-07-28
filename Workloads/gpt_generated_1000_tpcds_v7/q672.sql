WITH joined_data AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_visited,
        SUM(p.p_cost) AS total_promo_cost
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cc.cc_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND ws.web_country = 'United States'
    GROUP BY s.s_store_id, d.d_year
)
SELECT
    store_id,
    year,
    total_sales,
    total_returns,
    (total_sales - total_returns) AS net_sales,
    CASE WHEN total_sales > 0 THEN (total_sales - total_returns) / total_sales ELSE 0 END AS profit_ratio,
    web_pages_visited,
    total_promo_cost
FROM joined_data
WHERE total_sales > 10000
ORDER BY profit_ratio DESC
LIMIT 100
