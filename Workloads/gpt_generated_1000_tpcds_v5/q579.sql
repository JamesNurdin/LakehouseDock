WITH base AS (
    SELECT
        d.d_year,
        s.s_state,
        cd.cd_gender,
        r.r_reason_desc,
        CASE WHEN ss.ss_net_profit > 5000 THEN 'High' ELSE 'Low' END AS profit_category,
        ss.ss_net_profit,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cr.cr_return_amount,
        cr.cr_return_quantity
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s ON s.s_store_sk = ss.ss_store_sk
    JOIN tpcds.customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.reason r ON r.r_reason_sk = cr.cr_reason_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%damaged%'
      AND ss.ss_net_profit > 1000
      AND ws.ws_quantity >= 5
      AND cr.cr_return_quantity = 1
)
SELECT
    d_year,
    s_state,
    cd_gender,
    r_reason_desc,
    profit_category,
    COUNT(*) AS txn_count,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(ss_net_profit) AS avg_store_profit,
    MIN(ss_net_profit) AS min_store_profit,
    MAX(ss_net_profit) AS max_store_profit
FROM base
GROUP BY d_year, s_state, cd_gender, r_reason_desc, profit_category
ORDER BY total_store_sales DESC
LIMIT 100
