WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_class,
        cc.cc_state,
        p.p_promo_sk,
        p.p_promo_name,
        sm.sm_type,
        d_sold.d_year,
        d_promo_start.d_year AS promo_start_year,
        d_promo_end.d_year   AS promo_end_year,
        d_cc_open.d_year    AS cc_open_year,
        d_cc_closed.d_year  AS cc_closed_year,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_catalog_net_paid,
        SUM(ss.ss_net_paid)               AS total_store_net_paid,
        SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
       AND ss.ss_promo_sk   = p.p_promo_sk
    WHERE d_sold.d_year = 1918
      AND d_sold.d_month_seq BETWEEN 1200 AND 1300
      AND cc.cc_class IN ('small', 'medium')
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND d_cc_open.d_year <= 1918
      AND d_cc_closed.d_year >= 1918
      AND d_promo_start.d_year <= 1918
      AND d_promo_end.d_year >= 1918
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_class,
        cc.cc_state,
        p.p_promo_sk,
        p.p_promo_name,
        sm.sm_type,
        d_sold.d_year,
        d_promo_start.d_year,
        d_promo_end.d_year,
        d_cc_open.d_year,
        d_cc_closed.d_year
)
SELECT
    sa.cc_name,
    sa.cc_class,
    sa.cc_state,
    sa.p_promo_name,
    sa.sm_type,
    sa.d_year,
    sa.total_catalog_net_paid,
    sa.total_store_net_paid,
    sa.total_net_profit,
    sa.catalog_order_cnt,
    sa.store_ticket_cnt,
    (
        SELECT COUNT(DISTINCT wp.wp_web_page_sk)
        FROM web_page wp
        JOIN date_dim d_wp_creation
          ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
        WHERE d_wp_creation.d_year = 1918
          AND wp.wp_type = 'homepage'
          AND wp.wp_link_count < 200
          AND NOT EXISTS (
                SELECT 1
                FROM web_page wp2
                WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
                  AND wp2.wp_link_count > 500
          )
    ) AS homepage_pages_1918
FROM sales_agg sa
WHERE sa.total_net_profit > 10000
  AND sa.total_catalog_net_paid > 5000
  AND sa.total_store_net_paid > 2000
  AND sa.catalog_order_cnt >= 10
  AND sa.store_ticket_cnt >= 5
  AND NOT EXISTS (
        SELECT 1
        FROM web_page wp_ex
        JOIN date_dim d_wp_access
          ON wp_ex.wp_access_date_sk = d_wp_access.d_date_sk
        WHERE wp_ex.wp_type = 'landing'
          AND d_wp_access.d_year = 1918
          AND wp_ex.wp_link_count > 1000
  )
ORDER BY sa.total_net_profit DESC
LIMIT 100
