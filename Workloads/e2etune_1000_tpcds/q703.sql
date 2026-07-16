WITH returns_agg AS (
    SELECT ca.ca_state AS state,
           s.s_division_name AS division,
           td.t_hour AS hour,
           SUM(sr.sr_return_amt) AS total_return_amount,
           SUM(sr.sr_return_quantity) AS total_return_qty,
           COUNT(*) AS return_transactions
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_gmt_offset = -7.00
      AND s.s_state = ca.ca_state
      AND ca.ca_location_type = 'single family'
    GROUP BY ca.ca_state, s.s_division_name, td.t_hour
),
sales_agg AS (
    SELECT ca.ca_state AS state,
           td.t_hour AS hour,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(*) AS sales_transactions
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND ca.ca_gmt_offset = -7.00
      AND ca.ca_location_type = 'single family'
    GROUP BY ca.ca_state, td.t_hour
)
SELECT r.state,
       r.division,
       r.hour,
       r.total_return_amount,
       r.total_return_qty,
       r.return_transactions,
       s.total_sales,
       s.total_profit,
       s.sales_transactions,
       CASE WHEN s.total_sales > 0 THEN r.total_return_amount / s.total_sales ELSE NULL END AS return_to_sales_ratio,
       RANK() OVER (PARTITION BY r.state ORDER BY r.total_return_amount DESC) AS return_rank_by_state,
       RANK() OVER (ORDER BY s.total_sales DESC) AS overall_sales_rank
FROM returns_agg r
JOIN sales_agg s ON r.state = s.state AND r.hour = s.hour
WHERE s.total_sales > 0
ORDER BY return_to_sales_ratio DESC
LIMIT 200
