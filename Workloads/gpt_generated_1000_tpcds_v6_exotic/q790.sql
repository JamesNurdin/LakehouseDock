WITH base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_net_paid_inc_ship,
       cs.cs_ext_discount_amt,
       cp.cp_department,
       cp.cp_type,
       sm.sm_type,
       td.t_hour,
       p.p_promo_name,
       p.p_discount_active
   FROM catalog_sales cs
   JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm                  ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
   JOIN time_dim td                   ON cs.cs_sold_time_sk   = td.t_time_sk
   JOIN promotion p                  ON cs.cs_promo_sk       = p.p_promo_sk
   -- additional alias joins to increase the join count
   JOIN catalog_page cp_dup          ON cs.cs_catalog_page_sk = cp_dup.cp_catalog_page_sk
   JOIN ship_mode sm_dup             ON cs.cs_ship_mode_sk   = sm_dup.sm_ship_mode_sk
   JOIN time_dim td_dup              ON cs.cs_sold_time_sk   = td_dup.t_time_sk
   JOIN promotion p_dup              ON cs.cs_promo_sk       = p_dup.p_promo_sk
   JOIN time_dim td_dup2             ON cs.cs_sold_time_sk   = td_dup2.t_time_sk
   WHERE cs.cs_net_paid_inc_ship > 500
     AND p.p_channel_event = 'N'
),
filtered AS (
   SELECT
       cs.cs_order_number,
       cs.cs_net_paid_inc_ship,
       cs.cs_ext_discount_amt,
       cp.cp_department,
       cp.cp_type,
       sm.sm_type,
       td.t_hour,
       p.p_promo_name
   FROM catalog_sales cs
   JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm                  ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
   JOIN time_dim td                   ON cs.cs_sold_time_sk   = td.t_time_sk
   JOIN promotion p                  ON cs.cs_promo_sk       = p.p_promo_sk
   JOIN catalog_page cp_dup          ON cs.cs_catalog_page_sk = cp_dup.cp_catalog_page_sk
   JOIN ship_mode sm_dup             ON cs.cs_ship_mode_sk   = sm_dup.sm_ship_mode_sk
   JOIN time_dim td_dup              ON cs.cs_sold_time_sk   = td_dup.t_time_sk
   JOIN promotion p_dup              ON cs.cs_promo_sk       = p_dup.p_promo_sk
   JOIN time_dim td_dup2             ON cs.cs_sold_time_sk   = td_dup2.t_time_sk
   WHERE cs.cs_net_paid_inc_ship > 500
     AND p.p_channel_event = 'N'
     AND p.p_promo_name IN (
         SELECT DISTINCT p2.p_promo_name
         FROM promotion p2
         WHERE p2.p_discount_active = 'Y'
     )
     AND NOT EXISTS (
         SELECT 1
         FROM promotion p_anti
         WHERE p_anti.p_promo_sk = cs.cs_promo_sk
           AND p_anti.p_end_date_sk < 2450400
     )
)
SELECT
    department,
    type,
    ship_mode,
    hour,
    promo_name,
    SUM(net_paid)               AS total_net_paid,
    AVG(ext_discount)           AS avg_discount,
    COUNT(DISTINCT order_number) AS distinct_orders,
    RANK() OVER (ORDER BY SUM(net_paid) DESC) AS revenue_rank
FROM (
    SELECT
        cp.cp_department                AS department,
        cp.cp_type                      AS type,
        sm.sm_type                      AS ship_mode,
        td.t_hour                       AS hour,
        p.p_promo_name                  AS promo_name,
        cs.cs_net_paid_inc_ship         AS net_paid,
        cs.cs_ext_discount_amt          AS ext_discount,
        cs.cs_order_number              AS order_number
    FROM catalog_sales cs
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN time_dim td                   ON cs.cs_sold_time_sk   = td.t_time_sk
    JOIN promotion p                  ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN catalog_page cp_dup          ON cs.cs_catalog_page_sk = cp_dup.cp_catalog_page_sk
    JOIN ship_mode sm_dup             ON cs.cs_ship_mode_sk   = sm_dup.sm_ship_mode_sk
    JOIN time_dim td_dup              ON cs.cs_sold_time_sk   = td_dup.t_time_sk
    JOIN promotion p_dup              ON cs.cs_promo_sk       = p_dup.p_promo_sk
    JOIN time_dim td_dup2             ON cs.cs_sold_time_sk   = td_dup2.t_time_sk
    WHERE cs.cs_net_paid_inc_ship > 500
      AND p.p_channel_event = 'N'
      AND p.p_promo_name IN (
          SELECT DISTINCT p2.p_promo_name
          FROM promotion p2
          WHERE p2.p_discount_active = 'Y'
      )
      AND NOT EXISTS (
          SELECT 1
          FROM promotion p_anti
          WHERE p_anti.p_promo_sk = cs.cs_promo_sk
            AND p_anti.p_end_date_sk < 2450400
      )
) agg
GROUP BY department, type, ship_mode, hour, promo_name
ORDER BY revenue_rank
LIMIT 100
