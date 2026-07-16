WITH high_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1500
      AND cs.cs_ext_discount_amt > 800
      AND cs.cs_quantity >= 1
),
aggregated AS (
    SELECT
        ca_bill.ca_country AS bill_country,
        ca_ship.ca_country AS ship_country,
        sm.sm_type AS ship_type,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_marital_status AS ship_marital_status,
        hd_bill.hd_buy_potential AS bill_buy_potential,
        hd_ship.hd_buy_potential AS ship_buy_potential,
        COUNT(*) AS sales_cnt,
        SUM(hs.cs_net_profit) AS total_net_profit,
        SUM(hs.cs_net_paid) AS total_net_paid,
        AVG(hs.cs_ext_discount_amt) AS avg_discount
    FROM high_sales hs
    JOIN customer_address ca_bill ON hs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON hs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm ON hs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_bill ON hs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON hs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill ON hs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON hs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    GROUP BY
        ca_bill.ca_country,
        ca_ship.ca_country,
        sm.sm_type,
        cd_bill.cd_gender,
        cd_ship.cd_marital_status,
        hd_bill.hd_buy_potential,
        hd_ship.hd_buy_potential
    HAVING SUM(hs.cs_net_profit) > 20000
)
SELECT
    bill_country,
    ship_country,
    ship_type,
    bill_gender,
    ship_marital_status,
    bill_buy_potential,
    ship_buy_potential,
    sales_cnt,
    total_net_profit,
    total_net_paid,
    avg_discount,
    ROUND(total_net_profit / NULLIF(total_net_paid, 0), 4) AS profit_margin,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY profit_margin DESC
LIMIT 15
