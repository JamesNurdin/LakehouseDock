WITH sales_by_demo_state AS (
    SELECT
        cd.cd_gender AS gender,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_customers,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_coupon_amt) AS total_coupon_amt
    FROM catalog_sales cs
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cs.cs_sales_price > 30
      AND cs.cs_call_center_sk IN (8, 19, 13)
      AND cs.cs_net_paid_inc_tax BETWEEN 1000 AND 10000
      AND cs.cs_ship_addr_sk IN (5184251, 2121279, 5602324)
      AND cs.cs_catalog_page_sk = 97
      AND cs.cs_net_paid_inc_ship > 1500
    GROUP BY cd.cd_gender, ca_bill.ca_state, ca_ship.ca_state
    HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT
    gender,
    bill_state,
    ship_state,
    order_cnt,
    distinct_customers,
    total_net_profit,
    avg_sales_price,
    total_coupon_amt,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_by_demo_state
ORDER BY total_net_profit DESC
LIMIT 10
