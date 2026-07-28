WITH agg_sales_returns AS (
    SELECT
        cs.cs_call_center_sk,
        cc.cc_name,
        td.t_hour,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
       AND sr.sr_customer_sk = c.c_customer_sk
       AND sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE
        cc.cc_state = 'CA'                         -- filter 1
        AND cd.cd_marital_status = 'M'              -- filter 2
        AND cd.cd_purchase_estimate > 3000          -- filter 3
        AND cs.cs_ext_sales_price > 1000
    GROUP BY
        cs.cs_call_center_sk,
        cc.cc_name,
        td.t_hour
)
SELECT
    a.cc_name,
    a.t_hour,
    a.total_sales,
    a.total_returns,
    (a.total_sales - a.total_returns) AS net_amount,
    a.orders_cnt,
    (
        SELECT AVG(sub.total_sales - sub.total_returns)
        FROM agg_sales_returns sub
        WHERE sub.t_hour = a.t_hour
    ) AS avg_net_by_hour,
    (
        SELECT COUNT(DISTINCT c2.c_customer_sk)
        FROM customer c2
        JOIN catalog_sales cs2
            ON cs2.cs_bill_customer_sk = c2.c_customer_sk
        WHERE cs2.cs_call_center_sk = a.cs_call_center_sk
    ) AS distinct_customers_per_cc
FROM agg_sales_returns a
WHERE (a.total_sales - a.total_returns) > 0
ORDER BY net_amount DESC
LIMIT 100
