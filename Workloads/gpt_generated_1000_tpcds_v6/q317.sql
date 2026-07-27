/*
  Goal: Analyze sales performance per store in California, linking sales, customer address, household demographics, returns and store details.
  The query joins all five tables using the allowed join keys, applies realistic filter predicates, aggregates key metrics,
  includes a scalar subquery for overall average net paid, uses a CASE expression to flag profit vs loss, and orders stores by total sales.
*/
WITH avg_net_paid AS (
    SELECT AVG(cs_net_paid_inc_ship_tax) AS overall_avg
    FROM tpcds.catalog_sales
)
SELECT
    s.s_store_id,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
    AVG(sr.sr_fee) AS avg_return_fee,
    MAX(cs.cs_net_profit) AS max_profit,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    SUM(cs.cs_net_paid_inc_ship_tax) / (SELECT overall_avg FROM avg_net_paid) AS sales_vs_avg_ratio
FROM tpcds.catalog_sales cs
JOIN tpcds.customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
   AND sr.sr_addr_sk = ca.ca_address_sk
JOIN tpcds.store s
    ON sr.sr_store_sk = s.s_store_sk
WHERE cs.cs_ship_hdemo_sk IN (2581, 5128)
  AND cs.cs_net_paid_inc_ship_tax > 1000
  AND hd.hd_vehicle_count >= 1
  AND s.s_state = 'CA'
  AND sr.sr_fee < 30
GROUP BY s.s_store_id, s.s_state
ORDER BY total_sales DESC
LIMIT 20
