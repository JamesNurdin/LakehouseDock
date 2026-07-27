WITH avg_profit AS (
    SELECT avg(ws_net_profit) AS avg_ws_net_profit
    FROM tpcds.web_sales
)
SELECT order_number,
       return_amount,
       reason,
       county
FROM (
    SELECT wr.wr_order_number AS order_number,
           wr.wr_return_amt   AS return_amount,
           r.r_reason_desc    AS reason,
           ca.ca_county       AS county
    FROM tpcds.web_returns wr
    JOIN tpcds.web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ws.ws_net_profit > (SELECT avg_ws_net_profit FROM avg_profit)
      AND r.r_reason_desc LIKE '%color%'
) 
UNION ALL
SELECT order_number,
       return_amount,
       reason,
       county
FROM (
    SELECT wr.wr_order_number AS order_number,
           wr.wr_return_amt   AS return_amount,
           r.r_reason_desc    AS reason,
           ca.ca_county       AS county
    FROM tpcds.web_returns wr
    JOIN tpcds.web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ws.ws_net_profit <= (SELECT avg_ws_net_profit FROM avg_profit)
      AND r.r_reason_desc LIKE '%damaged%'
) 
ORDER BY return_amount DESC
LIMIT 100
