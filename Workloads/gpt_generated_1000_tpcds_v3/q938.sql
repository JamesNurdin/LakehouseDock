WITH sales_returns AS (
    SELECT
        ca.ca_county AS county,
        ca.ca_state AS state_name,
        SUM(cs.cs_ext_wholesale_cost * cs.cs_quantity) AS total_wholesale_cost,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid_inc_ship,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(sr.sr_store_credit) AS total_store_credit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE
        sr.sr_store_credit > 5.00
        AND sr.sr_return_time_sk BETWEEN 40000 AND 50000
        AND cs.cs_ext_wholesale_cost BETWEEN 500 AND 2000
        AND ca.ca_county IN ('Washington County', 'Mifflin County')
    GROUP BY ca.ca_county, ca.ca_state
)
SELECT
    county,
    state_name,
    total_wholesale_cost,
    total_net_paid_inc_ship,
    total_return_amt_inc_tax,
    total_store_credit,
    distinct_orders,
    distinct_returns,
    total_net_paid_inc_ship / NULLIF(distinct_orders, 0) AS avg_net_paid_per_order,
    (SELECT AVG(total_store_credit) FROM sales_returns) AS avg_store_credit_all_counties
FROM sales_returns
WHERE total_store_credit > (SELECT AVG(total_store_credit) FROM sales_returns)
ORDER BY total_store_credit DESC
LIMIT 100
