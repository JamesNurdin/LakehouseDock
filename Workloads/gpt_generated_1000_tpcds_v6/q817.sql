/* goal: Compute sales and profit metrics by warehouse, ship mode and customer state, include subtotals, profit category, distinct customers, and a running total of sales per warehouse */
WITH base AS (
    SELECT
        cs.cs_ship_date_sk,
        cs.cs_quantity,
        cs.cs_list_price,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_bill_addr_sk,
        ca.ca_state,
        sm.sm_type,
        sm.sm_contract,
        w.w_warehouse_name,
        w.w_country
    FROM catalog_sales cs
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ship_date_sk IN (2450830, 2450875)
      AND cs.cs_list_price >= 80
      AND sm.sm_contract = 'OrDuVy2H'
      AND w.w_country = 'United States'
),
agg AS (
    SELECT
        w_warehouse_name,
        sm_type,
        ca_state,
        SUM(cs_net_profit) AS sum_net_profit,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_list_price) AS avg_list_price,
        COUNT(DISTINCT cs_bill_addr_sk) AS distinct_customers,
        MIN(cs_ship_date_sk) AS first_ship_date_sk
    FROM base
    GROUP BY GROUPING SETS (
        (w_warehouse_name, sm_type, ca_state),
        (w_warehouse_name, sm_type),
        (w_warehouse_name),
        ()
    )
)
SELECT
    w_warehouse_name,
    sm_type,
    ca_state,
    CASE WHEN sum_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_category,
    total_quantity,
    total_sales,
    avg_list_price,
    distinct_customers,
    SUM(total_sales) OVER (
        PARTITION BY w_warehouse_name
        ORDER BY first_ship_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_sales
FROM agg
ORDER BY w_warehouse_name, sm_type, ca_state
LIMIT 100
