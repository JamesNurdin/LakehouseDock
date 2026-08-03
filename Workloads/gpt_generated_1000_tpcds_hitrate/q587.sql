WITH filtered_sales AS (
    SELECT
        cs.*,
        cd.cd_gender,
        hd.hd_income_band_sk,
        i.i_brand,
        inv.inv_warehouse_sk
    FROM catalog_sales cs
    FULL OUTER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE cs.cs_item_sk IS NOT NULL
      AND cs.cs_ext_ship_cost > 500
      AND cs.cs_net_paid_inc_ship_tax < 5000
      AND inv.inv_warehouse_sk IN (2, 13)
      AND hd.hd_income_band_sk = 15
      AND i.i_current_price BETWEEN 10 AND 100
      AND EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = cs.cs_item_sk
            AND inv2.inv_quantity_on_hand > 0
      )
)
SELECT
    cd_gender,
    hd_income_band_sk,
    i_brand,
    inv_warehouse_sk,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_ext_ship_cost) AS avg_ship_cost,
    SUM(CASE WHEN cs_net_profit > 0 THEN cs_net_profit ELSE 0 END) AS total_positive_profit,
    MIN(cs_ext_ship_cost) AS min_ship_cost,
    MAX(cs_ext_ship_cost) AS max_ship_cost
FROM filtered_sales
GROUP BY CUBE (cd_gender, hd_income_band_sk, i_brand, inv_warehouse_sk)
ORDER BY total_net_paid DESC
LIMIT 100
