WITH date_range AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = (SELECT MAX(d_year) FROM date_dim) - 1
),
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_call_center_sk AS cc_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        MAX(cs.cs_sold_date_sk) AS last_order_date_sk
    FROM catalog_sales cs
    JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, cs.cs_call_center_sk
),
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        NULL AS cc_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        MAX(ss.ss_sold_date_sk) AS last_order_date_sk
    FROM store_sales ss
    JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk
    GROUP BY ss.ss_customer_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        NULL AS cc_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_order_date_sk
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY ws.ws_bill_customer_sk
),
sales_union AS (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
customer_returns AS (
    SELECT
        cr.cr_returning_customer_sk AS cust_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count,
        MAX(cr.cr_returned_date_sk) AS last_return_date_sk
    FROM catalog_returns cr
    JOIN date_range dr ON cr.cr_returned_date_sk = dr.d_date_sk
    GROUP BY cr.cr_returning_customer_sk
    UNION ALL
    SELECT
        sr.sr_customer_sk AS cust_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count,
        MAX(sr.sr_returned_date_sk) AS last_return_date_sk
    FROM store_returns sr
    JOIN date_range dr ON sr.sr_returned_date_sk = dr.d_date_sk
    GROUP BY sr.sr_customer_sk
    UNION ALL
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count,
        MAX(wr.wr_returned_date_sk) AS last_return_date_sk
    FROM web_returns wr
    JOIN date_range dr ON wr.wr_returned_date_sk = dr.d_date_sk
    GROUP BY wr.wr_refunded_customer_sk
),
cust_agg AS (
    SELECT
        s.cust_sk,
        s.cc_sk,
        COALESCE(s.total_profit, 0) AS total_sales_profit,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        COALESCE(s.order_count, 0) AS order_cnt,
        COALESCE(r.return_count, 0) AS return_cnt,
        COALESCE(s.last_order_date_sk, 0) AS last_order_date_sk,
        COALESCE(r.last_return_date_sk, 0) AS last_return_date_sk,
        COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit
    FROM (
        SELECT cust_sk, cc_sk,
               SUM(total_profit) AS total_profit,
               SUM(order_count) AS order_count,
               MAX(last_order_date_sk) AS last_order_date_sk
        FROM sales_union
        GROUP BY cust_sk, cc_sk
    ) s
    LEFT JOIN (
        SELECT cust_sk,
               SUM(total_return_loss) AS total_return_loss,
               SUM(return_count) AS return_count,
               MAX(last_return_date_sk) AS last_return_date_sk
        FROM customer_returns
        GROUP BY cust_sk
    ) r ON s.cust_sk = r.cust_sk
),
ranked AS (
    SELECT
        ca.cust_sk,
        ca.cc_sk,
        ca.net_profit,
        ca.total_sales_profit,
        ca.total_return_loss,
        ca.order_cnt,
        ca.return_cnt,
        ca.last_order_date_sk,
        ca.last_return_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ca.cc_sk ORDER BY ca.net_profit DESC) AS rn,
        CASE WHEN ca.last_order_date_sk IS NULL OR ca.last_order_date_sk = 0 THEN 'NoOrders' ELSE 'HasOrders' END AS order_flag
    FROM cust_agg ca
),
final AS (
    SELECT
        COALESCE(cc.cc_name, 'No Call Center') AS call_center_name,
        COALESCE(c.c_customer_id, 'UNKNOWN') || ':' || COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS customer_key_name,
        r.rn,
        r.net_profit,
        r.total_sales_profit,
        r.total_return_loss,
        r.order_cnt,
        r.return_cnt,
        d_last_order.d_date AS last_order_date,
        d_last_return.d_date AS last_return_date,
        r.order_flag,
        (SELECT COUNT(DISTINCT cs.cs_item_sk)
         FROM catalog_sales cs
         WHERE cs.cs_bill_customer_sk = r.cust_sk
           AND cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_range)) AS distinct_catalog_items,
        (SELECT COUNT(DISTINCT ss.ss_item_sk)
         FROM store_sales ss
         WHERE ss.ss_customer_sk = r.cust_sk
           AND ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_range)) AS distinct_store_items,
        (SELECT COUNT(DISTINCT ws.ws_item_sk)
         FROM web_sales ws
         WHERE ws.ws_bill_customer_sk = r.cust_sk
           AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_range)) AS distinct_web_items,
        SUM(r.net_profit) OVER (PARTITION BY r.cc_sk) AS total_cc_net_profit
    FROM ranked r
    LEFT JOIN call_center cc ON r.cc_sk = cc.cc_call_center_sk
    LEFT JOIN customer c ON r.cust_sk = c.c_customer_sk
    LEFT JOIN date_dim d_last_order ON r.last_order_date_sk = d_last_order.d_date_sk
    LEFT JOIN date_dim d_last_return ON r.last_return_date_sk = d_last_return.d_date_sk
    WHERE r.rn <= 5
)
SELECT *
FROM final
ORDER BY call_center_name NULLS LAST, net_profit DESC
