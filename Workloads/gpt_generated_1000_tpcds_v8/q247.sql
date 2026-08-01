WITH first_part AS (
    SELECT
        ss.ss_sold_date_sk                     AS date_sk,
        ss.ss_sold_time_sk                     AS time_sk,
        ss.ss_item_sk                          AS item_sk,
        ss.ss_customer_sk                      AS customer_sk,
        ss.ss_store_sk                         AS store_sk,
        ss.ss_promo_sk                         AS promo_sk,
        ss.ss_net_paid                         AS net_paid,
        ss.ss_net_paid_inc_tax                 AS net_paid_inc_tax,
        ss.ss_quantity                         AS quantity,
        d.d_year                               AS year,
        t.t_meal_time                          AS meal_time,
        c.c_first_name                         AS first_name,
        c.c_last_name                          AS last_name,
        cd.cd_gender                           AS gender,
        hd.hd_income_band_sk                   AS income_band,
        st.s_state                             AS state,
        p.p_promo_name                         AS promo_name,
        w.w_warehouse_name                     AS warehouse_name,
        inv.inv_quantity_on_hand               AS quantity_on_hand,
        wp.wp_url                              AS url,
        CASE
            WHEN ss.ss_net_paid_inc_tax > 1000 THEN 'High'
            WHEN ss.ss_net_paid_inc_tax > 500  THEN 'Medium'
            ELSE 'Low'
        END                                   AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_net_paid_inc_tax DESC) AS sales_rank,
        (
            SELECT COUNT(*)
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = ss.ss_customer_sk
              AND ss2.ss_sold_date_sk > ss.ss_sold_date_sk
        )                                      AS later_sales_cnt
    FROM store_sales ss
    JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t   ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c   ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store st    ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w   ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
                          AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND st.s_state = 'TX'
      AND cd.cd_gender = 'M'
      AND ss.ss_store_sk IN (
          SELECT ss2.ss_store_sk
          FROM store_sales ss2
          WHERE ss2.ss_net_paid > 1000
      )
),
second_part AS (
    SELECT
        cr.cr_returned_date_sk                 AS date_sk,
        cr.cr_returned_time_sk                 AS time_sk,
        cr.cr_item_sk                          AS item_sk,
        cr.cr_refunded_customer_sk             AS customer_sk,
        CAST(NULL AS integer)                 AS store_sk,
        CAST(NULL AS integer)                 AS promo_sk,
        cr.cr_return_amount                    AS net_paid,
        cr.cr_return_amt_inc_tax               AS net_paid_inc_tax,
        cr.cr_return_quantity                  AS quantity,
        d.d_year                               AS year,
        t.t_meal_time                          AS meal_time,
        c.c_first_name                         AS first_name,
        c.c_last_name                          AS last_name,
        cd.cd_gender                           AS gender,
        hd.hd_income_band_sk                   AS income_band,
        CAST(NULL AS varchar)                 AS state,
        CAST(NULL AS varchar)                 AS promo_name,
        w.w_warehouse_name                     AS warehouse_name,
        inv.inv_quantity_on_hand               AS quantity_on_hand,
        CAST(NULL AS varchar)                 AS url,
        CASE
            WHEN cr.cr_return_amount > 500 THEN 'High'
            WHEN cr.cr_return_amount > 200 THEN 'Medium'
            ELSE 'Low'
        END                                   AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_warehouse_sk ORDER BY cr.cr_return_amount DESC) AS sales_rank,
        (
            SELECT COUNT(*)
            FROM catalog_returns cr2
            WHERE cr2.cr_refunded_customer_sk = cr.cr_refunded_customer_sk
              AND cr2.cr_returned_date_sk > cr.cr_returned_date_sk
        )                                      AS later_sales_cnt
    FROM catalog_returns cr
    JOIN date_dim d   ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t   ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c   ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN warehouse w   ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r       ON cr.cr_reason_sk = r.r_reason_sk
    WHERE EXISTS (
        SELECT 1
        FROM call_center cc
        WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
          AND cc.cc_market_manager = 'John Doe'
    )
      AND d.d_year = 2001
      AND cp.cp_type = 'Electronic'
      AND r.r_reason_desc LIKE '%defect%'
)
SELECT *
FROM (
    SELECT * FROM first_part
    UNION DISTINCT
    SELECT * FROM second_part
) u
ORDER BY net_paid_inc_tax DESC
LIMIT 100
