WITH joined AS (
    SELECT
        sr.sr_return_amt_inc_tax,
        sr.sr_store_credit,
        sr.sr_fee,
        ca.ca_state,
        ca.ca_county,
        ws.ws_ext_list_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_gmt_offset BETWEEN -10.00 AND -5.00
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND sr.sr_return_amt_inc_tax > 500
      AND ws.ws_ext_list_price > 1000
),
agg AS (
    SELECT
        ca_state,
        ca_county,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(ws_ext_list_price) AS total_list_price
    FROM joined
    GROUP BY ca_state, ca_county
)
SELECT
    ca_state,
    ca_county,
    total_return_amt_inc_tax,
    total_list_price,
    CASE WHEN total_return_amt_inc_tax > 10000 THEN 'HIGH' ELSE 'MEDIUM' END AS return_category,
    RANK() OVER (ORDER BY total_return_amt_inc_tax DESC) AS return_rank,
    DENSE_RANK() OVER (ORDER BY total_list_price DESC) AS sales_dense_rank
FROM agg
ORDER BY total_return_amt_inc_tax DESC
LIMIT 100
