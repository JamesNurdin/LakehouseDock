WITH cs_join AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_catalog_page_id,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_sales cs
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_department = 'Electronics'
      AND cs.cs_sold_date_sk BETWEEN 2451000 AND 2451100
      AND hd.hd_dep_count >= 2
      AND ib.ib_upper_bound <= 100000
)
SELECT
    cs_join.cp_department,
    cs_join.cp_catalog_page_id,
    cs_join.hd_buy_potential,
    cs_join.ib_lower_bound,
    cs_join.ib_upper_bound,
    SUM(cs_join.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(cs_join.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs_join.cs_item_sk) AS distinct_items,
    CASE
        WHEN SUM(cs_join.cs_net_profit) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_flag,
    SUM(qty) AS total_quantity_unrolled
FROM cs_join
LEFT JOIN store_sales ss
    ON ss.ss_hdemo_sk = cs_join.hd_demo_sk
   AND ss.ss_sold_date_sk BETWEEN 2451000 AND 2451100
LEFT JOIN UNNEST(array[cs_join.cs_quantity, ss.ss_quantity]) AS t(qty) ON TRUE
WHERE cs_join.cs_net_profit > (SELECT AVG(cs_net_profit) FROM catalog_sales)
GROUP BY
    cs_join.cp_department,
    cs_join.cp_catalog_page_id,
    cs_join.hd_buy_potential,
    cs_join.ib_lower_bound,
    cs_join.ib_upper_bound
HAVING SUM(cs_join.cs_net_paid_inc_tax) > 1000
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
