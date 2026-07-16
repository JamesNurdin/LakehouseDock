WITH store_agg AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_net_profit,
        AVG(ss.ss_coupon_amt) AS avg_store_coupon,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_count
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY c.c_customer_id
),
web_agg AS (
    SELECT
        c.c_customer_id,
        w.w_state,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_net_profit,
        AVG(ws.ws_coupon_amt) AS avg_web_coupon,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY c.c_customer_id, w.w_state
),
returns_agg AS (
    SELECT
        c.c_customer_id,
        r.r_reason_desc,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY c.c_customer_id, r.r_reason_desc
),
joined AS (
    SELECT
        ca.c_customer_id,
        ca.total_store_sales,
        ca.total_store_net_profit,
        wa.total_web_sales,
        wa.total_web_net_profit,
        wa.w_state,
        ra.r_reason_desc,
        ra.return_cnt,
        ra.total_return_amount,
        ra.total_return_loss,
        ROW_NUMBER() OVER (PARTITION BY ca.c_customer_id ORDER BY ra.total_return_loss DESC) AS rn,
        cust.c_preferred_cust_flag
    FROM store_agg ca
    LEFT JOIN web_agg wa ON ca.c_customer_id = wa.c_customer_id
    LEFT JOIN returns_agg ra ON ca.c_customer_id = ra.c_customer_id
    JOIN customer cust ON ca.c_customer_id = cust.c_customer_id
)
SELECT
    c_customer_id,
    total_store_sales,
    total_store_net_profit,
    total_web_sales,
    total_web_net_profit,
    w_state,
    r_reason_desc,
    return_cnt,
    total_return_amount,
    total_return_loss
FROM joined
WHERE c_preferred_cust_flag = 'Y'
  AND rn = 1
ORDER BY total_store_net_profit DESC
LIMIT 100
