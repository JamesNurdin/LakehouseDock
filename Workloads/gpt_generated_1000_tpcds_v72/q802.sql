/* goal: Summarize web sales by billing gender and marital status, filter for high‑value orders and demographic conditions, rank gender groups by total sales, and categorize sales level */
WITH sales_demo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        cd_bill.cd_gender AS bill_gender,
        cd_bill.cd_marital_status AS bill_marital_status,
        cd_bill.cd_dep_college_count,
        cd_ship.cd_gender AS ship_gender,
        cd_ship.cd_dep_employed_count
    FROM web_sales ws
    LEFT JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE ws.ws_net_paid_inc_ship_tax > 2000
      AND ws.ws_ext_tax BETWEEN 50 AND 250
      AND cd_bill.cd_dep_college_count >= 1
      AND cd_ship.cd_dep_employed_count >= 2
),
agg AS (
    SELECT
        bill_gender,
        bill_marital_status,
        COUNT(*) AS order_cnt,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_paid_inc_ship_tax) AS total_net_paid
    FROM sales_demo
    GROUP BY bill_gender, bill_marital_status
    HAVING COUNT(*) >= 5
)
SELECT
    bill_gender,
    bill_marital_status,
    order_cnt,
    total_sales,
    total_net_paid,
    RANK() OVER (PARTITION BY bill_gender ORDER BY total_sales DESC) AS gender_sales_rank,
    CASE
        WHEN total_sales > 50000 THEN 'High'
        WHEN total_sales > 20000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM agg
ORDER BY gender_sales_rank, total_sales DESC
LIMIT 100
