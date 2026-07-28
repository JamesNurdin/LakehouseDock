WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        c.c_customer_id,
        ca.ca_state,
        r.r_reason_desc,
        sr.sr_return_amt_inc_tax,
        wr.wr_return_amt,
        ws.ws_net_profit,
        ws.ws_net_paid,
        wh.w_warehouse_name,
        wsite.web_site_id
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE wsite.web_rec_start_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
      AND sr.sr_return_amt_inc_tax > 1000
      AND r.r_reason_desc LIKE '%model%'
),
agg_customer AS (
    SELECT
        c_customer_id AS customer_id,
        ca_state,
        SUM(sr_return_amt_inc_tax) AS total_store_return,
        SUM(wr_return_amt) AS total_web_return,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS txn_cnt
    FROM base
    GROUP BY c_customer_id, ca_state
)
SELECT
    ca_state,
    AVG(total_store_return) AS avg_store_return,
    AVG(total_web_return) AS avg_web_return,
    AVG(total_net_profit) AS avg_net_profit,
    SUM(txn_cnt) AS total_transactions
FROM agg_customer
GROUP BY ca_state
HAVING AVG(total_store_return) > 2000
ORDER BY avg_store_return DESC
LIMIT 100
