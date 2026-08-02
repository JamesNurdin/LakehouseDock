WITH catalog_data AS (
    SELECT
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS net_profit,
        cc.cc_market_manager,
        sm.sm_type,
        w.w_warehouse_name,
        cp.cp_description,
        regexp_extract(cp.cp_description, '\\w+', 0) AS desc_first_word
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cc.cc_market_manager, '^J')
      AND sm.sm_type LIKE '%Express%'
      AND cp.cp_description LIKE '%special%'
),
store_data AS (
    SELECT
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS net_profit,
        ca.ca_city,
        hd.hd_income_band_sk,
        substr(ca.ca_city, 1, 3) AS city_prefix
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_city LIKE 'A%'
      AND hd.hd_income_band_sk >= 5
),
avg_profit AS (
    SELECT
        cc.cc_market_manager,
        avg(cs.cs_net_profit) AS avg_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY cc.cc_market_manager
),
buy_potential_dim AS (
    SELECT DISTINCT hd.hd_buy_potential
    FROM household_demographics hd
    LIMIT 5
),
segment_dim AS (
    SELECT 'Low' AS segment UNION ALL SELECT 'Mid' UNION ALL SELECT 'High' AS segment
),
combined AS (
    SELECT
        'Catalog' AS source,
        cd.cc_market_manager AS manager,
        cd.sm_type AS ship_type,
        cd.sales_amount,
        cd.net_profit,
        cd.desc_first_word AS description_word,
        NULL AS city_prefix,
        NULL AS income_band,
        ROW_NUMBER() OVER (PARTITION BY cd.cc_market_manager ORDER BY cd.net_profit DESC) AS profit_rank,
        (SELECT avg(ap.avg_net_profit) FROM avg_profit ap WHERE ap.cc_market_manager = cd.cc_market_manager) AS overall_avg_profit
    FROM catalog_data cd
    WHERE EXISTS (
        SELECT 1 FROM warehouse w2
        WHERE w2.w_warehouse_name LIKE '%Central%'
          AND w2.w_warehouse_sq_ft > 50000
    )
    UNION ALL
    SELECT
        'Store' AS source,
        NULL AS manager,
        NULL AS ship_type,
        sd.sales_amount,
        sd.net_profit,
        NULL AS description_word,
        sd.city_prefix,
        sd.hd_income_band_sk AS income_band,
        ROW_NUMBER() OVER (PARTITION BY sd.hd_income_band_sk ORDER BY sd.net_profit DESC) AS profit_rank,
        NULL AS overall_avg_profit
    FROM store_data sd
    WHERE EXISTS (
        SELECT 1 FROM call_center cc2
        WHERE cc2.cc_market_manager LIKE '%a%'
    )
)
SELECT
    comb.source,
    comb.manager,
    comb.ship_type,
    comb.sales_amount,
    comb.net_profit,
    comb.description_word,
    comb.city_prefix,
    comb.income_band,
    comb.profit_rank,
    comb.overall_avg_profit,
    bpd.hd_buy_potential,
    seg.segment,
    concat(COALESCE(comb.manager, 'N/A'), '-', seg.segment) AS manager_segment
FROM combined comb
CROSS JOIN buy_potential_dim bpd
CROSS JOIN segment_dim seg
WHERE comb.sales_amount > 1000
ORDER BY comb.source, comb.sales_amount DESC, comb.profit_rank
LIMIT 100
