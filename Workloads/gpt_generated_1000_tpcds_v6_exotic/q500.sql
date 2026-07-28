WITH base AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_net_profit,
       ss.ss_customer_sk AS c_customer_sk,
       s.s_store_name,
       s.s_state,
       i.i_brand,
       c.c_birth_year,
       cp.cp_catalog_page_number,
       sm.sm_type,
       p.p_discount_active
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                           AND sr.sr_item_sk = ss.ss_item_sk
   LEFT JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk
   LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
   LEFT JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
   LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE s.s_state = 'CA'
     AND i.i_brand = 'BrandA'
     AND p.p_discount_active = 'Y'
     AND c.c_birth_year BETWEEN 1970 AND 1980
     AND cp.cp_catalog_page_number IN (5, 8, 14)
     AND sm.sm_type = 'AIR'
),
agg AS (
   SELECT
       s_store_name,
       s_state,
       i_brand,
       c_customer_sk,
       SUM(ss_net_profit) AS total_profit,
       COUNT(DISTINCT ss_ticket_number) AS total_sales
   FROM base
   GROUP BY s_store_name, s_state, i_brand, c_customer_sk
)
SELECT
    s_store_name,
    s_state,
    i_brand,
    total_profit,
    total_sales,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_profit DESC) AS profit_rank_state,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            JOIN reason r3 ON cr2.cr_reason_sk = r3.r_reason_sk
            WHERE cr2.cr_refunded_customer_sk = agg.c_customer_sk
              AND r3.r_reason_desc = 'Damaged'
        ) THEN 'HasDamagedReturn'
        ELSE 'NoDamagedReturn'
    END AS damaged_return_flag,
    (SELECT AVG(ss_net_profit) FROM store_sales) AS avg_net_profit_all_stores
FROM agg
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr3
    WHERE cr3.cr_refunded_customer_sk = agg.c_customer_sk
      AND cr3.cr_return_quantity > 0
)
ORDER BY total_profit DESC
LIMIT 100
