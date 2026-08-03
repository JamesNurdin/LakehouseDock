-- Goal: Analyze promotion performance by ship carrier and customer demographics, applying regex and pattern filters, and compute profit categories with correlated store‑sales metrics.
WITH promo_agg AS (
    SELECT p.p_promo_sk,
           sm.sm_carrier,
           cd.cd_gender,
           ca.ca_city,
           ca.ca_state,
           SUM(cs.cs_net_paid) AS total_net_paid,
           regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_digits
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE regexp_like(p.p_promo_name, '^A.*[0-9]')
      AND ca.ca_state LIKE 'C%'
    GROUP BY p.p_promo_sk, sm.sm_carrier, cd.cd_gender, ca.ca_city, ca.ca_state,
             regexp_extract(p.p_promo_name, '(\\d+)', 1)
    UNION DISTINCT
    SELECT p.p_promo_sk,
           sm.sm_carrier,
           cd.cd_gender,
           ca.ca_city,
           ca.ca_state,
           SUM(cs.cs_net_paid) AS total_net_paid,
           regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_digits
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE sm.sm_carrier LIKE '%AIR%'
      AND cd.cd_education_status = 'College'
    GROUP BY p.p_promo_sk, sm.sm_carrier, cd.cd_gender, ca.ca_city, ca.ca_state,
             regexp_extract(p.p_promo_name, '(\\d+)', 1)
)
SELECT pa.p_promo_sk,
       pa.sm_carrier,
       pa.cd_gender,
       pa.ca_city,
       pa.ca_state,
       pa.ca_city || ', ' || pa.ca_state AS location,
       pa.total_net_paid,
       CASE WHEN pa.total_net_paid > 50000 THEN 'High'
            WHEN pa.total_net_paid > 20000 THEN 'Medium'
            ELSE 'Low' END AS profit_category,
       (SELECT SUM(ss.ss_net_profit)
        FROM store_sales ss
        WHERE ss.ss_promo_sk = pa.p_promo_sk) AS total_store_profit,
       (SELECT COUNT(*)
        FROM store_sales ss2
        WHERE ss2.ss_promo_sk = pa.p_promo_sk
          AND ss2.ss_net_profit > 1000) AS high_profit_txn_cnt
FROM promo_agg pa
ORDER BY pa.total_net_paid DESC
LIMIT 100
