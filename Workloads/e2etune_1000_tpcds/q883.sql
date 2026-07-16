WITH bill_stats AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education,
        SUM(cs.cs_net_profit) AS bill_net_profit,
        AVG(cs.cs_sales_price) AS bill_avg_price,
        COUNT(DISTINCT cs.cs_order_number) AS bill_order_cnt
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sales_price BETWEEN 60 AND 150
      AND cs.cs_ext_discount_amt < 20
      AND cs.cs_ext_ship_cost < 500
      AND cs.cs_sold_date_sk BETWEEN 2450820 AND 2450826
      AND cs.cs_quantity > 1
    GROUP BY cd.cd_gender, cd.cd_education_status
),
ship_stats AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education,
        SUM(cs.cs_net_profit) AS ship_net_profit,
        AVG(cs.cs_sales_price) AS ship_avg_price,
        COUNT(DISTINCT cs.cs_order_number) AS ship_order_cnt
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sales_price BETWEEN 60 AND 150
      AND cs.cs_ext_discount_amt < 20
      AND cs.cs_ext_ship_cost < 500
      AND cs.cs_sold_date_sk BETWEEN 2450820 AND 2450826
      AND cs.cs_quantity > 1
    GROUP BY cd.cd_gender, cd.cd_education_status
),
combined AS (
    SELECT
        b.gender,
        b.education,
        b.bill_net_profit,
        s.ship_net_profit,
        b.bill_net_profit - s.ship_net_profit AS profit_diff,
        CASE WHEN s.ship_net_profit = 0 THEN NULL
             ELSE b.bill_net_profit / s.ship_net_profit END AS profit_ratio,
        b.bill_order_cnt,
        s.ship_order_cnt
    FROM bill_stats b
    JOIN ship_stats s
        ON b.gender = s.gender
       AND b.education = s.education
)
SELECT
    gender,
    education,
    bill_net_profit,
    ship_net_profit,
    profit_diff,
    profit_ratio,
    bill_order_cnt,
    ship_order_cnt,
    RANK() OVER (ORDER BY profit_diff DESC) AS diff_rank
FROM combined
WHERE profit_diff > 0
ORDER BY diff_rank
LIMIT 10
