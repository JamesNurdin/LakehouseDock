WITH demo_intersect AS (
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_income_band_sk IN (8, 11, 14)
      AND hd_dep_count >= 3
    INTERSECT
    SELECT cs_bill_hdemo_sk
    FROM catalog_sales
    WHERE cs_ext_ship_cost > 200
      AND cs_ext_discount_amt < 500
),
joined_data AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        td.t_hour,
        p.p_promo_id,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        cs.cs_ext_sales_price AS cs_ext_sales_price
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN demo_intersect di ON hd.hd_demo_sk = di.hd_demo_sk
    WHERE td.t_hour BETWEEN 7 AND 15
      AND p.p_channel_tv = 'Y'
      AND p.p_channel_dmail = 'N'
      AND cs.cs_ext_ship_cost > 200
      AND hd.hd_buy_potential = '>10000'
),
aggregated AS (
    SELECT
        jd.hd_demo_sk,
        jd.hd_income_band_sk,
        jd.t_hour,
        jd.p_promo_id,
        SUM(jd.ss_net_profit + jd.cs_net_profit) AS total_net_profit
    FROM joined_data jd
    GROUP BY jd.hd_demo_sk, jd.hd_income_band_sk, jd.t_hour, jd.p_promo_id
)
SELECT
    a.hd_demo_sk,
    a.hd_income_band_sk,
    a.t_hour,
    a.p_promo_id,
    a.total_net_profit,
    RANK() OVER (PARTITION BY a.p_promo_id ORDER BY a.total_net_profit DESC) AS profit_rank,
    (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_hdemo_sk = a.hd_demo_sk
    ) AS avg_catalog_sales_price_per_demo
FROM aggregated a
ORDER BY a.total_net_profit DESC
LIMIT 100
