WITH first AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt,
        cs.cs_ext_ship_cost,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY cs.cs_ext_sales_price DESC) AS rn,
        (
            SELECT SUM(cs2.cs_quantity)
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_customer_sk = cs.cs_bill_customer_sk
        ) AS total_qty_for_customer
    FROM catalog_sales cs
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_coupon_amt > 0
        AND cs.cs_ext_ship_cost < 2000
        AND cs.cs_quantity >= 2
        AND hd.hd_buy_potential = '5001-10000'
        AND hd.hd_dep_count BETWEEN 1 AND 5
),
second AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt,
        cs.cs_ext_ship_cost,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY cs.cs_ext_sales_price DESC) AS rn,
        (
            SELECT SUM(cs2.cs_quantity)
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_customer_sk = cs.cs_bill_customer_sk
        ) AS total_qty_for_customer
    FROM catalog_sales cs
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_coupon_amt > 0
        AND cs.cs_ext_ship_cost < 2000
        AND cs.cs_quantity >= 2
        AND hd.hd_buy_potential = '>10000'
        AND hd.hd_dep_count BETWEEN 1 AND 5
)
SELECT *
FROM (
    SELECT * FROM first
    UNION
    SELECT * FROM second
) AS combined
ORDER BY total_qty_for_customer DESC, rn ASC
LIMIT 100
