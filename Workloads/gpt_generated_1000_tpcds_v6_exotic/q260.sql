WITH bill_sales AS (
    SELECT
        cs.cs_order_number AS order_number,
        hd.hd_buy_potential AS buy_potential,
        cs.cs_ext_sales_price AS sales_price,
        (SELECT AVG(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         WHERE cs2.cs_bill_hdemo_sk = cs.cs_bill_hdemo_sk) AS avg_hdemo_price,
        SUM(cs.cs_ext_sales_price) OVER (PARTITION BY hd.hd_buy_potential) AS sum_by_potential
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk = 12
      AND cs.cs_ext_sales_price > 1000
),
ship_sales AS (
    SELECT
        cs.cs_order_number AS order_number,
        hd.hd_buy_potential AS buy_potential,
        cs.cs_ext_sales_price AS sales_price,
        (SELECT AVG(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         WHERE cs2.cs_ship_hdemo_sk = cs.cs_ship_hdemo_sk) AS avg_hdemo_price,
        SUM(cs.cs_ext_sales_price) OVER (PARTITION BY hd.hd_buy_potential) AS sum_by_potential
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count >= 2
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs3
          WHERE cs3.cs_ship_hdemo_sk = cs.cs_ship_hdemo_sk
            AND cs3.cs_ext_sales_price > 500
      )
),
combined AS (
    SELECT order_number, buy_potential, sales_price, avg_hdemo_price, sum_by_potential
    FROM bill_sales
    UNION ALL
    SELECT order_number, buy_potential, sales_price, avg_hdemo_price, sum_by_potential
    FROM ship_sales
)
SELECT
    order_number,
    buy_potential,
    sales_price,
    avg_hdemo_price,
    sum_by_potential,
    ROW_NUMBER() OVER (ORDER BY sales_price DESC) AS rn
FROM combined
ORDER BY rn
LIMIT 100
