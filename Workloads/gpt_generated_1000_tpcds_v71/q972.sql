WITH sales_join AS (
    SELECT
        cc.cc_name,
        cc.cc_company,
        cc.cc_mkt_id,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_profit
    FROM
        tpcds.call_center AS cc
        INNER JOIN tpcds.catalog_sales AS cs
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        INNER JOIN tpcds.household_demographics AS hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
        cc.cc_company = 2                     -- filter on company id
        AND cc.cc_mkt_id = 5                  -- filter on market id
        AND cs.cs_ext_ship_cost > 1000        -- high shipping cost rows only
        AND hd.hd_dep_count >= 1              -- households with at least one dependent
        AND hd.hd_vehicle_count >= 0         -- households that own a vehicle or more
        AND cs.cs_net_paid_inc_ship < 8000   -- moderate net paid amount
)
SELECT
    cc_name,
    hd_buy_potential,
    SUM(cs_ext_ship_cost)      AS total_ship_cost,
    AVG(cs_net_paid_inc_ship)  AS avg_paid_inc_ship,
    COUNT(*)                   AS sales_cnt,
    MIN(cs_net_profit)         AS min_profit,
    MAX(cs_net_profit)         AS max_profit,
    GROUPING(cc_name)          AS grp_cc_name,
    GROUPING(hd_buy_potential) AS grp_hd_buy_potential
FROM
    sales_join
GROUP BY
    GROUPING SETS (
        (cc_name, hd_buy_potential),
        (cc_name),
        (hd_buy_potential),
        ()
    )
ORDER BY
    grp_cc_name,
    grp_hd_buy_potential,
    cc_name,
    hd_buy_potential
