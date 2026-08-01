WITH sales_with_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        ca.ca_state,
        ca.ca_location_type,
        hd.hd_income_band_sk,
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship,
        ws.ws_ext_wholesale_cost,
        ws.ws_net_profit,
        wr.wr_return_amt
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE
        ws.ws_net_paid_inc_ship > 3000
        AND ws.ws_ext_wholesale_cost BETWEEN 200 AND 500
        AND ca.ca_state = 'CA'
        AND ca.ca_location_type = 'apartment'
        AND hd.hd_income_band_sk IN (6, 7, 8)
        AND c.c_preferred_cust_flag = 'Y'
        AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2451000
)
SELECT
    ca_state,
    hd_income_band_sk,
    c_preferred_cust_flag,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(ws_net_paid_inc_ship) AS total_net_paid,
    AVG(ws_ext_wholesale_cost) AS avg_wholesale_cost,
    MIN(ws_net_profit) AS min_profit,
    MAX(ws_net_profit) AS max_profit,
    SUM(COALESCE(wr_return_amt, 0)) AS total_return_amount,
    (
        SELECT AVG(ws2.ws_net_paid_inc_ship)
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_sold_date_sk BETWEEN 2450800 AND 2451000
    ) AS avg_net_paid_all_sales
FROM sales_with_returns
WHERE EXISTS (
    SELECT 1
    FROM tpcds.web_returns wr2
    WHERE wr2.wr_order_number = ws_order_number
      AND wr2.wr_return_amt > 500
)
GROUP BY ca_state, hd_income_band_sk, c_preferred_cust_flag
HAVING SUM(COALESCE(wr_return_amt, 0)) > 1000
ORDER BY total_net_paid DESC, order_cnt DESC
LIMIT 100
