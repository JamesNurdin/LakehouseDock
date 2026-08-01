WITH overall_avg AS (
    SELECT AVG(ss_net_profit) AS avg_profit
    FROM store_sales
),

sub_start AS (
    SELECT
        dd.d_year AS sale_year,
        pr.p_promo_id AS promo_id,
        pr.p_channel_email AS channel,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
        SUM(ss.ss_net_profit) / oa.avg_profit AS profit_to_avg_ratio,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customer_count
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion pr ON ss.ss_promo_sk = pr.p_promo_sk
    CROSS JOIN LATERAL (
        SELECT d2.d_year AS promo_start_year
        FROM date_dim d2
        WHERE d2.d_date_sk = pr.p_start_date_sk
    ) AS start_yr
    CROSS JOIN overall_avg oa
    WHERE hd.hd_income_band_sk >= 12
      AND start_yr.promo_start_year = 2001
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd2
          WHERE hd2.hd_demo_sk = ss.ss_hdemo_sk
            AND hd2.hd_vehicle_count > 1
      )
    GROUP BY dd.d_year, pr.p_promo_id, pr.p_channel_email, oa.avg_profit
    HAVING SUM(ss.ss_net_profit) > 5000
),

sub_end AS (
    SELECT
        dd.d_year AS sale_year,
        pr.p_promo_id AS promo_id,
        pr.p_channel_email AS channel,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 8000 THEN 'High' ELSE 'Low' END AS profit_category,
        SUM(ss.ss_net_profit) / oa.avg_profit AS profit_to_avg_ratio,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customer_count
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion pr ON ss.ss_promo_sk = pr.p_promo_sk
    CROSS JOIN LATERAL (
        SELECT d2.d_year AS promo_end_year
        FROM date_dim d2
        WHERE d2.d_date_sk = pr.p_end_date_sk
    ) AS end_yr
    CROSS JOIN overall_avg oa
    WHERE hd.hd_income_band_sk < 12
      AND end_yr.promo_end_year = 2001
      AND pr.p_promo_id IN (
          SELECT DISTINCT p2.p_promo_id
          FROM promotion p2
          WHERE p2.p_channel_email = 'Y'
      )
    GROUP BY dd.d_year, pr.p_promo_id, pr.p_channel_email, oa.avg_profit
    HAVING SUM(ss.ss_net_profit) > 5000
)

SELECT
    sale_year,
    promo_id,
    channel,
    total_profit,
    profit_category,
    profit_to_avg_ratio,
    distinct_customer_count
FROM (
    SELECT sale_year, promo_id, channel, total_profit, profit_category, profit_to_avg_ratio, distinct_customer_count
    FROM sub_start
    UNION ALL
    SELECT sale_year, promo_id, channel, total_profit, profit_category, profit_to_avg_ratio, distinct_customer_count
    FROM sub_end
) AS combined
ORDER BY total_profit DESC
LIMIT 100
