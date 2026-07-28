-- Goal: Identify promotional campaigns with specific ID or name patterns that generated high net profit across store and catalog sales, filtered by customer demographics and income bands, and ranked by aggregated profit.
WITH sales_agg AS (
    SELECT DISTINCT
        p.p_promo_id,
        p.p_promo_name,
        CONCAT(p.p_promo_id, '-', CAST(p.p_promo_sk AS VARCHAR)) AS promo_key,
        SUBSTR(p.p_promo_name, 1, 5) AS promo_prefix,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t                ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE REGEXP_LIKE(p.p_promo_id, '^PR[0-9]{3}$')
      AND p.p_discount_active = 'N'
      AND cd.cd_gender = 'M'
      AND ib.ib_upper_bound >= 50000
      AND t.t_hour BETWEEN 9 AND 21
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_promo_sk
),
catalog_agg AS (
    SELECT DISTINCT
        p.p_promo_id,
        p.p_promo_name,
        CONCAT(p.p_promo_id, '-', CAST(p.p_promo_sk AS VARCHAR)) AS promo_key,
        SUBSTR(p.p_promo_name, 1, 5) AS promo_prefix,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t                ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '.*Summer.*')
      AND p.p_purpose LIKE '%Clearance%'
      AND cd.cd_marital_status = 'M'
      AND ib.ib_lower_bound < 30000
      AND t.t_hour >= 12
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_promo_sk
)
SELECT
    promo_key,
    promo_prefix,
    SUM(total_net_profit)      AS agg_profit,
    SUM(total_quantity)        AS agg_quantity,
    SUM(distinct_units)        AS agg_distinct_units
FROM (
    SELECT
        promo_key,
        promo_prefix,
        total_net_profit,
        total_quantity,
        distinct_tickets AS distinct_units
    FROM sales_agg
    UNION ALL
    SELECT
        promo_key,
        promo_prefix,
        total_net_profit,
        total_quantity,
        distinct_orders AS distinct_units
    FROM catalog_agg
) combined
GROUP BY promo_key, promo_prefix
HAVING SUM(total_net_profit) > 2000
ORDER BY agg_profit DESC
LIMIT 100
