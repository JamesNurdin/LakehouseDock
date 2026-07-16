WITH combined_sales AS (
    SELECT 
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_store_sk AS sales_entity_sk,
        ss.ss_customer_sk AS cust_sk,
        ss.ss_net_profit AS profit,
        'store' AS source
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_web_page_sk AS sales_entity_sk,
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_net_profit AS profit,
        'web' AS source
    FROM web_sales ws
    UNION ALL
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_call_center_sk AS sales_entity_sk,
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_net_profit AS profit,
        'catalog' AS source
    FROM catalog_sales cs
),
date_sales AS (
    SELECT 
        d.d_date_sk AS date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        cs.source,
        COUNT(*) AS num_transactions,
        SUM(cs.profit) AS total_profit,
        CASE WHEN COUNT(*) = 0 THEN NULL ELSE SUM(cs.profit) / COUNT(*) END AS profit_per_txn,
        MAX(cs.sales_entity_sk) AS entity_sk
    FROM combined_sales cs
    JOIN date_dim d ON cs.date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date, d.d_year, d.d_month_seq, cs.source
),
top_customers AS (
    SELECT 
        cs.cust_sk,
        cs.source,
        d.d_date_sk AS date_sk,
        d.d_date AS date,
        cs.profit,
        ROW_NUMBER() OVER (PARTITION BY cs.source, d.d_date ORDER BY cs.profit DESC) AS rn
    FROM combined_sales cs
    JOIN date_dim d ON cs.date_sk = d.d_date_sk
    WHERE cs.profit > 0
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_demo_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
demographic_avg_profit AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cs.profit) AS avg_demo_profit
    FROM combined_sales cs
    JOIN customer c ON cs.cust_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk
)
SELECT 
    ds.d_date,
    ds.d_year,
    ds.source,
    ds.num_transactions,
    ds.total_profit,
    ds.profit_per_txn,
    COALESCE(cd.full_name, 'UNKNOWN') AS top_customer_name,
    CASE 
        WHEN dap.avg_demo_profit IS NULL THEN 'NoDemo'
        WHEN tc.profit > dap.avg_demo_profit THEN 'Above'
        ELSE 'BelowOrEqual'
    END AS profit_vs_demo,
    (SELECT COUNT(*) 
     FROM store_returns sr 
     WHERE sr.sr_customer_sk = cd.c_customer_sk 
       AND sr.sr_returned_date_sk = ds.date_sk) AS return_count,
    CONCAT('Profit ratio: ', CAST(ROUND(ds.total_profit / NULLIF(ds.num_transactions,0), 2) AS VARCHAR)) AS profit_ratio_str,
    CASE 
        WHEN ds.source = 'store' THEN s.s_store_name
        WHEN ds.source = 'catalog' THEN cc.cc_name
        WHEN ds.source = 'web' THEN wp.wp_url
        ELSE 'N/A'
    END AS sales_entity_name
FROM date_sales ds
LEFT JOIN top_customers tc 
    ON tc.rn = 1 
   AND tc.source = ds.source 
   AND tc.date_sk = ds.date_sk
LEFT JOIN customer_details cd 
    ON cd.c_customer_sk = tc.cust_sk
LEFT JOIN demographic_avg_profit dap 
    ON dap.cd_demo_sk = cd.cd_demo_sk
LEFT JOIN store s 
    ON ds.source = 'store' AND ds.entity_sk = s.s_store_sk
LEFT JOIN call_center cc 
    ON ds.source = 'catalog' AND ds.entity_sk = cc.cc_call_center_sk
LEFT JOIN web_page wp 
    ON ds.source = 'web' AND ds.entity_sk = wp.wp_web_page_sk
WHERE ds.d_year = 2000
  AND ds.source IN ('store','web')
ORDER BY ds.d_date DESC, ds.source
