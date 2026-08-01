WITH joined_data AS (
    SELECT
        s.s_store_name            AS s_store_name,
        p_cs.p_promo_name         AS p_promo_name,
        p_cs.p_discount_active    AS p_discount_active,
        p_extra.p_channel_press   AS p_channel_press,
        sm.sm_type                AS sm_type,
        sm_extra.sm_code          AS sm_code,
        w.w_warehouse_name        AS w_warehouse_name,
        w_extra.w_city            AS w_city,
        s_extra.s_manager         AS s_manager,
        cs.cs_net_paid            AS cs_net_paid,
        ss.ss_net_paid_inc_tax    AS ss_net_paid_inc_tax,
        cs.cs_promo_sk            AS cs_promo_sk,
        w.w_state                 AS w_state,
        w.w_gmt_offset            AS w_gmt_offset
    FROM
        tpcds.catalog_sales cs
    JOIN tpcds.promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_promo_sk = p_cs.p_promo_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.store s_extra
        ON ss.ss_store_sk = s_extra.s_store_sk
    JOIN tpcds.promotion p_extra
        ON cs.cs_promo_sk = p_extra.p_promo_sk
        AND p_extra.p_channel_press = 'N'
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.ship_mode sm_extra
        ON cs.cs_ship_mode_sk = sm_extra.sm_ship_mode_sk
        AND sm_extra.sm_code = 'AIR'
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.warehouse w_extra
        ON cs.cs_warehouse_sk = w_extra.w_warehouse_sk
        AND w_extra.w_suite_number = 'Suite 350'
    WHERE
        s.s_state = 'CA'
        AND p_cs.p_discount_active = 'Y'
)
SELECT
    s_store_name,
    p_promo_name,
    sm_type,
    sm_code,
    w_warehouse_name,
    w_city,
    s_manager,
    SUM(cs_net_paid)               AS total_catalog_net_paid,
    SUM(ss_net_paid_inc_tax)       AS total_store_net_paid_inc_tax,
    COUNT(*)                       AS transaction_count,
    (
        SELECT SUM(cs2.cs_net_paid)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_promo_sk = joined_data.cs_promo_sk
    )                               AS catalog_total_for_promo
FROM joined_data
WHERE EXISTS (
    SELECT 1
    FROM tpcds.warehouse w_check
    WHERE w_check.w_state = joined_data.w_state
      AND w_check.w_gmt_offset = joined_data.w_gmt_offset
)
GROUP BY
    s_store_name,
    p_promo_name,
    sm_type,
    sm_code,
    w_warehouse_name,
    w_city,
    s_manager,
    cs_promo_sk,
    w_state,
    w_gmt_offset
ORDER BY
    total_catalog_net_paid DESC
LIMIT 100
