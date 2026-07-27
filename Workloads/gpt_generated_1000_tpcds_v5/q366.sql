WITH sales_returns_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS sales_orders,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_coupon_amt > 1000
      AND sr.sr_fee < 50
      AND cd.cd_dep_college_count >= 3
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_education_status
)
SELECT
    cd_demo_sk,
    cd_gender,
    cd_education_status,
    total_sales,
    total_profit,
    total_returns,
    sales_orders,
    return_tickets,
    total_profit / NULLIF(sales_orders, 0) AS avg_profit_per_order,
    total_returns / NULLIF(return_tickets, 0) AS avg_return_amt_per_ticket
FROM sales_returns_agg
WHERE total_sales > 50000
ORDER BY avg_profit_per_order DESC
LIMIT 100
