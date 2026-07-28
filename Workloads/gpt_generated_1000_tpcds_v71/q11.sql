WITH filtered_sales AS (
    SELECT 
        cs.cs_ship_mode_sk,
        sm.sm_type,
        hd.hd_buy_potential,
        cs.cs_net_profit,
        cs.cs_ext_tax,
        cs.cs_quantity,
        cs.cs_ext_sales_price
    FROM tpcds.catalog_sales cs
    JOIN tpcds.household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_net_profit > 0
      AND cs.cs_ext_tax > 0
      AND hd.hd_buy_potential = '1001-5000'
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_sales cs2
          WHERE cs2.cs_ship_mode_sk = cs.cs_ship_mode_sk
            AND cs2.cs_quantity > 5
      )
)
SELECT 
    sm_type,
    hd_buy_potential,
    SUM(cs_net_profit) AS total_profit,
    COUNT(*) AS sales_count,
    CASE 
        WHEN SUM(cs_net_profit) > (SELECT AVG(cs_net_profit) FROM tpcds.catalog_sales) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS profit_category,
    RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
FROM filtered_sales
GROUP BY sm_type, hd_buy_potential
ORDER BY profit_rank
