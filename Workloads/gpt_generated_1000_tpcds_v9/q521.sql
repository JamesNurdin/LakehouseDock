WITH per_state_income AS (
    SELECT
        ca_bill.ca_state AS state,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        AVG(cs.cs_net_paid) AS avg_net_paid
    FROM catalog_sales cs
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_ext_sales_price > (
            SELECT AVG(ub)
            FROM (
                SELECT DISTINCT ib_upper_bound AS ub
                FROM income_band
            ) AS uniq_ib
        )
        AND cs.cs_quantity >= 2
        AND hd_bill.hd_vehicle_count >= 2
        AND ca_bill.ca_state = 'CA'
        AND ib.ib_upper_bound >= 80000
    GROUP BY ca_bill.ca_state, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    state,
    ib_lower_bound,
    ib_upper_bound,
    total_profit,
    total_sales,
    distinct_orders,
    avg_net_paid,
    total_profit / NULLIF(distinct_orders, 0) AS profit_per_order
FROM per_state_income
WHERE total_profit / NULLIF(distinct_orders, 0) > (
    SELECT AVG(total_profit / NULLIF(distinct_orders, 0))
    FROM per_state_income
)
ORDER BY total_profit DESC
LIMIT 100
