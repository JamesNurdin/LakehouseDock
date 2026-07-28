/*
  Goal: Analyze the profitability of catalog sales for male, single customers when the associated promotion name contains a numeric identifier and the shipment is handled by carriers whose code starts with "U". The query extracts a three‑letter code from the promotion name, groups results by promotion name, that extracted code, and the ship‑mode type, and returns total profit, average quantity and transaction count.
*/
WITH filtered_sales AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_quantity,
        p.p_promo_name,
        REGEXP_EXTRACT(p.p_promo_name, '([A-Z]{3})', 1) AS promo_code,
        sm.sm_type
    FROM
        catalog_sales cs
        INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'S'
        AND REGEXP_LIKE(p.p_promo_name, '[0-9]')
        AND sm.sm_carrier LIKE 'U%'
)
SELECT
    promo_name,
    promo_code,
    sm_type,
    SUM(cs_net_profit) AS total_profit,
    AVG(cs_quantity) AS avg_quantity,
    COUNT(*) AS sales_cnt
FROM (
    SELECT
        cs_net_profit,
        cs_quantity,
        p_promo_name AS promo_name,
        promo_code,
        sm_type
    FROM filtered_sales
) t
GROUP BY
    promo_name,
    promo_code,
    sm_type
ORDER BY
    total_profit DESC
