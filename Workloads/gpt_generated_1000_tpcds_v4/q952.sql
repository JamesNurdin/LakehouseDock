WITH sr_agg AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    WHERE sr.sr_return_amt > 500
    GROUP BY sr.sr_customer_sk
)
SELECT
    cd.cd_gender,
    w.w_state,
    COUNT(DISTINCT c.c_customer_sk) AS cust_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(sr_agg.total_net_loss) AS total_return_loss,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN sr_agg
    ON sr_agg.sr_customer_sk = c.c_customer_sk
WHERE
    c.c_preferred_cust_flag = 'Y'
    AND cd.cd_education_status = 'Advanced Degree'
    AND cd.cd_dep_college_count >= 3
    AND ws.ws_sales_price BETWEEN 20 AND 70
    AND ws.ws_ext_wholesale_cost > 1000
    AND EXISTS (
        SELECT 1 FROM warehouse w2
        WHERE w2.w_warehouse_sk = ws.ws_warehouse_sk
          AND w2.w_state = 'CA'
    )
GROUP BY cd.cd_gender, w.w_state
HAVING COUNT(DISTINCT c.c_customer_sk) >= 5
ORDER BY total_net_paid DESC
LIMIT 100
