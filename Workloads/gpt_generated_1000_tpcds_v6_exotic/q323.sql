/*
  Goal: Analyze net sales and net loss by state and city for a highly filtered set of transactions, 
  showing subtotals per state, overall averages, cumulative totals, and ranking of cities by sales.
*/
WITH sales_returns AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        ca.ca_country,
        cs.cs_quantity,
        cs.cs_ext_wholesale_cost,
        cs.cs_ext_tax,
        cs.cs_coupon_amt,
        cs.cs_net_paid,
        sr.sr_store_credit,
        sr.sr_net_loss,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_state = 'CA'
      AND ca.ca_city = 'Hill 7th'
      AND cs.cs_ext_wholesale_cost > 2000
      AND cs.cs_ext_tax BETWEEN 50 AND 150
      AND cs.cs_coupon_amt < 500
      AND sr.sr_store_credit > 100
      AND sr.sr_return_quantity = 1
)
SELECT
    ca_state,
    ca_city,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(cs_coupon_amt) AS avg_coupon_amount,
    COUNT(*) AS transaction_count,
    (SELECT AVG(cs_net_paid) FROM catalog_sales) AS overall_avg_net_paid,
    SUM(SUM(cs_net_paid)) OVER (
        PARTITION BY ca_state 
        ORDER BY ca_city 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_state_net_paid,
    RANK() OVER (
        PARTITION BY ca_state 
        ORDER BY SUM(cs_net_paid) DESC
    ) AS city_sales_rank
FROM sales_returns
GROUP BY ROLLUP (ca_state, ca_city)
HAVING SUM(cs_net_paid) > 0
ORDER BY ca_state, ca_city
LIMIT 100
