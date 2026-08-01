WITH
/* Sample a fraction of catalog_sales */
sampled_catalog_sales AS (
    SELECT cs.cs_sold_date_sk,
           cs.cs_sold_time_sk,
           cs.cs_ship_date_sk,
           cs.cs_call_center_sk,
           cs.cs_catalog_page_sk,
           cs.cs_ship_mode_sk,
           cs.cs_warehouse_sk,
           cs.cs_promo_sk,
           cs.cs_item_sk,
           cs.cs_order_number,
           cs.cs_net_paid,
           cs.cs_net_profit,
           cs.cs_bill_cdemo_sk
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
),
/* Join the sampled sales to all dimension tables */
joined_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d_sold.d_year                AS sold_year,
        t_sold.t_hour                AS sold_hour,
        cc.cc_name                   AS call_center_name,
        cp.cp_department             AS catalog_department,
        sm.sm_type                   AS ship_type,
        w.w_warehouse_name           AS warehouse_name,
        p.p_promo_name               AS promo_name,
        cd.cd_gender                 AS gender,
        cs.cs_bill_cdemo_sk          AS demo_sk
    FROM sampled_catalog_sales cs
    LEFT JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
),
/* Returns that have a specific reason (used later for anti‑join) */
returns_with_reason AS (
    SELECT cr.cr_order_number,
           r.r_reason_desc
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%Gift%'
),
/* Web sales enriched with dimensions */
web_joined AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d_sold.d_year                AS sold_year,
        t_sold.t_hour                AS sold_hour,
        sm.sm_type                   AS ship_type,
        w.w_warehouse_name           AS warehouse_name,
        p.p_promo_name               AS promo_name,
        cd.cd_gender                 AS gender,
        wp.wp_type                   AS page_type,
        wsit.web_state               AS web_state
    FROM web_sales ws
    LEFT JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
),
/* Union of catalog and web sales (distinct) */
union_all_sales AS (
    SELECT cs_order_number AS order_number,
           cs_net_paid      AS net_paid,
           cs_net_profit    AS net_profit,
           sold_year,
           sold_hour,
           ship_type,
           warehouse_name,
           promo_name,
           gender,
           'catalog'        AS src
    FROM joined_sales
    UNION
    SELECT ws_order_number,
           ws_net_paid,
           ws_net_profit,
           sold_year,
           sold_hour,
           ship_type,
           warehouse_name,
           promo_name,
           gender,
           'web'            AS src
    FROM web_joined
),
/* Orders that appear in catalog_sales but NOT in web_sales (EXCEPT) */
order_number_diff AS (
    SELECT cs_order_number AS order_number FROM catalog_sales
    EXCEPT
    SELECT ws_order_number    FROM web_sales
),
/* Full outer join between call_center and date_dim on closed date */
full_center_date AS (
    SELECT cc.cc_call_center_sk AS key_sk,
           cc.cc_name           AS name,
           d.d_date             AS closed_date,
           'call_center'        AS source
    FROM call_center cc
    FULL OUTER JOIN date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
),
/* Aggregate, rank and apply filters */
final_agg AS (
    SELECT
        src,
        sold_year,
        ship_type,
        COUNT(*)                            AS order_cnt,
        SUM(net_paid)                       AS total_paid,
        SUM(net_profit)                     AS total_profit,
        RANK() OVER (PARTITION BY src ORDER BY SUM(net_profit) DESC) AS profit_rank
    FROM union_all_sales u
    WHERE u.order_number IN (SELECT order_number FROM order_number_diff)          -- EXCEPT usage
      AND u.order_number NOT IN (SELECT cr_order_number FROM returns_with_reason) -- anti‑join
      AND u.sold_year BETWEEN 2000 AND 2005                                    -- filter 1
      AND u.ship_type IS NOT NULL                                               -- filter 2
      AND u.warehouse_name LIKE 'WH%'                                           -- filter 3
      AND u.promo_name IS NOT NULL                                             -- filter 4
      AND u.gender = 'M'                                                        -- filter 5
    GROUP BY src, sold_year, ship_type
),
/* Add a moving total window function */
final_result AS (
    SELECT
        f.src,
        f.sold_year,
        f.ship_type,
        f.order_cnt,
        f.total_paid,
        f.total_profit,
        f.profit_rank,
        SUM(f.total_paid) OVER (PARTITION BY f.src ORDER BY f.sold_year
                                 ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_total_paid_3yr
    FROM final_agg f
)
/* Union with the full outer‑joined call_center/date_dim rows (distinct) */
SELECT
    fr.src,
    fr.sold_year,
    fr.ship_type,
    fr.order_cnt,
    fr.total_paid,
    fr.total_profit,
    fr.profit_rank,
    fr.moving_total_paid_3yr
FROM final_result fr
UNION
SELECT
    fc.source            AS src,
    NULL                AS sold_year,
    NULL                AS ship_type,
    NULL                AS order_cnt,
    NULL                AS total_paid,
    NULL                AS total_profit,
    NULL                AS profit_rank,
    NULL                AS moving_total_paid_3yr
FROM full_center_date fc
ORDER BY src, sold_year NULLS LAST, profit_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
