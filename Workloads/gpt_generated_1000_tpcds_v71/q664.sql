WITH cs_agg AS (
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        SUM(cs_net_profit) AS cs_total_profit,
        COUNT(*) AS cs_sales_cnt
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2451545 AND 2452000
      AND cs_list_price > 20
      AND cs_quantity >= 1
      AND cs_ext_discount_amt < 500
      AND cs_ext_ship_cost > 0
    GROUP BY cs_sold_date_sk, cs_sold_time_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_market_id,
    td.t_hour,
    cd.cd_education_status,
    ib.ib_lower_bound,
    p.p_promo_name,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    COALESCE(cs_agg.cs_total_profit, 0) AS catalog_sales_profit,
    ROW_NUMBER() OVER (PARTITION BY s.s_market_id ORDER BY SUM(ss.ss_net_profit) DESC) AS market_store_rank,
    CASE
        WHEN SUM(ss.ss_net_profit) > COALESCE(cs_agg.cs_total_profit, 0) THEN 'Store higher'
        ELSE 'Catalog higher'
    END AS profit_comparison
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN cs_agg
    ON cs_agg.cs_sold_time_sk = td.t_time_sk
WHERE s.s_state = 'CA'
  AND s.s_market_id IN (1, 2, 5)
  AND td.t_hour BETWEEN 9 AND 17
  AND ss.ss_quantity > 2
  AND ss.ss_net_paid >= 100
  AND cd.cd_gender = 'M'
  AND ib.ib_upper_bound <= 100000
  AND p.p_discount_active = 'Y'
  AND ca.ca_state = 'CA'
  AND ca.ca_gmt_offset BETWEEN -8 AND -5
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_market_id,
    td.t_hour,
    cd.cd_education_status,
    ib.ib_lower_bound,
    p.p_promo_name,
    cs_agg.cs_total_profit
ORDER BY store_sales_profit DESC
LIMIT 100
