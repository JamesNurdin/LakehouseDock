WITH sales_returns AS (
    SELECT
        s.s_store_id AS store_id,
        t.t_hour AS hour_of_day,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(cs.cs_ext_sales_price) - SUM(sr.sr_return_amt) AS net_profit
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c_ret
        ON sr.sr_customer_sk = c_ret.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE cs.cs_ext_wholesale_cost > 2000
      AND cs.cs_ext_list_price < 5000
      AND c_bill.c_birth_country IN ('UKRAINE', 'PHILIPPINES')
      AND c_bill.c_salutation = 'Mrs.'
      AND s.s_country = 'United States'
      AND s.s_street_type = 'Ave'
      AND t.t_hour BETWEEN 9 AND 17
      AND sr.sr_return_quantity > 1
    GROUP BY s.s_store_id, t.t_hour
)
SELECT
    store_id,
    SUM(net_profit) AS total_net_profit,
    AVG(net_profit) AS avg_hourly_profit,
    COUNT(*) AS hour_count
FROM sales_returns
GROUP BY store_id
HAVING SUM(net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
