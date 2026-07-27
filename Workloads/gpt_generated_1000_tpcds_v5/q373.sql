WITH sales_returns AS (
    SELECT
        ca.ca_state,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COUNT(DISTINCT wr.wr_order_number) AS return_transactions
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'N'
      AND hd.hd_dep_count >= 2
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND d.d_year = 2002
    GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    ca_state,
    AVG(total_profit) AS avg_profit_per_income_band,
    SUM(total_sales) AS state_sales,
    SUM(total_returns) AS state_returns
FROM sales_returns
WHERE ib_upper_bound > (
    SELECT MAX(ib_upper_bound)
    FROM tpcds.income_band
    WHERE ib_lower_bound > 50000
)
GROUP BY ca_state
HAVING AVG(total_profit) > 1000
ORDER BY avg_profit_per_income_band DESC
