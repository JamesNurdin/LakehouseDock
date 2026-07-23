WITH
filtered_promotions AS (
    SELECT p.p_promo_sk,
           p.p_promo_id,
           p.p_promo_name,
           p.p_channel_details,
           CONCAT(p.p_promo_name, ' (', p.p_promo_id, ')') AS promo_full_name,
           SUBSTRING(p.p_promo_id FROM 1 FOR 5) AS promo_id_prefix,
           REGEXP_EXTRACT(p.p_channel_details, '(?i)(common|good)', 1) AS channel_keyword
    FROM promotion p
    WHERE REGEXP_LIKE(p.p_channel_details, '(?i)common')
      AND p.p_promo_name LIKE '%Sale%'
),
catalog_sales_agg AS (
    SELECT cs.cs_promo_sk AS promo_sk,
           COUNT(*) AS cat_order_cnt,
           SUM(cs.cs_net_profit) AS cat_total_profit
    FROM catalog_sales cs
    JOIN filtered_promotions fp ON cs.cs_promo_sk = fp.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_product_name LIKE '%-%'
    GROUP BY cs.cs_promo_sk
),
store_sales_agg AS (
    SELECT ss.ss_promo_sk AS promo_sk,
           COUNT(*) AS store_order_cnt,
           SUM(ss.ss_net_profit) AS store_total_profit
    FROM store_sales ss
    JOIN filtered_promotions fp ON ss.ss_promo_sk = fp.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%price%'
    GROUP BY ss.ss_promo_sk
),
promo_total AS (
    SELECT fp.p_promo_sk,
           fp.p_promo_id,
           fp.p_promo_name,
           fp.promo_full_name,
           fp.promo_id_prefix,
           fp.channel_keyword,
           COALESCE(ca.cat_order_cnt, 0) AS cat_order_cnt,
           COALESCE(ca.cat_total_profit, 0) AS cat_total_profit,
           COALESCE(sa.store_order_cnt, 0) AS store_order_cnt,
           COALESCE(sa.store_total_profit, 0) AS store_total_profit,
           (COALESCE(ca.cat_total_profit, 0) + COALESCE(sa.store_total_profit, 0)) AS total_profit
    FROM filtered_promotions fp
    LEFT JOIN catalog_sales_agg ca ON fp.p_promo_sk = ca.promo_sk
    LEFT JOIN store_sales_agg sa ON fp.p_promo_sk = sa.promo_sk
),
average_profit AS (
    SELECT AVG(total_profit) AS avg_profit FROM promo_total
)
SELECT
    pt.p_promo_id,
    pt.p_promo_name,
    pt.promo_full_name,
    pt.promo_id_prefix,
    pt.channel_keyword,
    pt.cat_order_cnt,
    pt.store_order_cnt,
    pt.total_profit,
    CASE
        WHEN pt.total_profit > (SELECT avg_profit FROM average_profit) THEN 'Top Performer'
        ELSE 'Average Performer'
    END AS performance_category
FROM promo_total pt
ORDER BY pt.total_profit DESC
LIMIT 100
