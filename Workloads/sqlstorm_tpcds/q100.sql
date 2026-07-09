WITH
    sales_agg AS (
        SELECT c.c_customer_sk,
               COALESCE(ss.store_net_paid, 0) AS store_net_paid,
               COALESCE(cs.catalog_net_paid, 0) AS catalog_net_paid,
               COALESCE(ws.web_net_paid, 0) AS web_net_paid,
               COALESCE(ss.store_net_profit, 0) AS store_net_profit,
               COALESCE(cs.catalog_net_profit, 0) AS catalog_net_profit,
               COALESCE(ws.web_net_profit, 0) AS web_net_profit
        FROM customer c
        LEFT JOIN (
            SELECT ss_customer_sk AS cust_sk,
                   SUM(ss_net_paid) AS store_net_paid,
                   SUM(ss_net_profit) AS store_net_profit
            FROM store_sales
            GROUP BY ss_customer_sk
        ) ss ON ss.cust_sk = c.c_customer_sk
        LEFT JOIN (
            SELECT cs_bill_customer_sk AS cust_sk,
                   SUM(cs_net_paid) AS catalog_net_paid,
                   SUM(cs_net_profit) AS catalog_net_profit
            FROM catalog_sales
            GROUP BY cs_bill_customer_sk
        ) cs ON cs.cust_sk = c.c_customer_sk
        LEFT JOIN (
            SELECT ws_bill_customer_sk AS cust_sk,
                   SUM(ws_net_paid) AS web_net_paid,
                   SUM(ws_net_profit) AS web_net_profit
            FROM web_sales
            GROUP BY ws_bill_customer_sk
        ) ws ON ws.cust_sk = c.c_customer_sk
    ),
    returns_agg AS (
        SELECT c.c_customer_sk,
               COALESCE(cr.catalog_return_amount, 0) AS catalog_return_amount,
               COALESCE(sr.store_return_amount, 0) AS store_return_amount,
               COALESCE(wr.web_return_amount, 0) AS web_return_amount
        FROM customer c
        LEFT JOIN (
            SELECT cr_returning_customer_sk AS cust_sk,
                   SUM(cr_return_amount) AS catalog_return_amount
            FROM catalog_returns
            GROUP BY cr_returning_customer_sk
        ) cr ON cr.cust_sk = c.c_customer_sk
        LEFT JOIN (
            SELECT sr_customer_sk AS cust_sk,
                   SUM(sr_return_amt) AS store_return_amount
            FROM store_returns
            GROUP BY sr_customer_sk
        ) sr ON sr.cust_sk = c.c_customer_sk
        LEFT JOIN (
            SELECT wr_returning_customer_sk AS cust_sk,
                   SUM(wr_return_amt) AS web_return_amount
            FROM web_returns
            GROUP BY wr_returning_customer_sk
        ) wr ON wr.cust_sk = c.c_customer_sk
    ),
    combined AS (
        SELECT 
            s.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            COALESCE(s.store_net_paid, 0) + COALESCE(s.catalog_net_paid, 0) + COALESCE(s.web_net_paid, 0) AS total_net_paid,
            COALESCE(s.store_net_profit, 0) + COALESCE(s.catalog_net_profit, 0) + COALESCE(s.web_net_profit, 0) AS total_net_profit,
            COALESCE(r.catalog_return_amount, 0) + COALESCE(r.store_return_amount, 0) + COALESCE(r.web_return_amount, 0) AS total_return_amount,
            CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS full_name,
            CASE 
                WHEN (COALESCE(s.store_net_paid, 0) + COALESCE(s.catalog_net_paid, 0) + COALESCE(s.web_net_paid, 0)) = 0 THEN 'NO_SALES'
                WHEN (COALESCE(r.catalog_return_amount, 0) + COALESCE(r.store_return_amount, 0) + COALESCE(r.web_return_amount, 0)) > 
                     GREATEST(COALESCE(s.store_net_paid, 0), COALESCE(s.catalog_net_paid, 0), COALESCE(s.web_net_paid, 0)) * 0.2
                THEN 'HIGH_RETURN'
                ELSE 'NORMAL'
            END AS sales_return_flag,
            CASE 
                WHEN NULLIF(COALESCE(s.store_net_paid, 0) + COALESCE(s.catalog_net_paid, 0) + COALESCE(s.web_net_paid, 0), 0) IS NULL THEN NULL
                ELSE (COALESCE(r.catalog_return_amount, 0) + COALESCE(r.store_return_amount, 0) + COALESCE(r.web_return_amount, 0))
                     / (COALESCE(s.store_net_paid, 0) + COALESCE(s.catalog_net_paid, 0) + COALESCE(s.web_net_paid, 0))
            END AS return_to_sales_ratio
        FROM sales_agg s
        JOIN customer c ON c.c_customer_sk = s.c_customer_sk
        LEFT JOIN returns_agg r ON r.c_customer_sk = s.c_customer_sk
    ),
    ranked AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (ORDER BY total_net_paid DESC NULLS LAST) AS rn,
            RANK() OVER (ORDER BY total_net_profit DESC NULLS LAST) AS profit_rank,
            PERCENT_RANK() OVER (ORDER BY total_return_amount ASC NULLS FIRST) AS return_pct_rank,
            NTILE(10) OVER (ORDER BY total_net_paid DESC) AS decile
        FROM combined
    ),
    high_profit AS (
        SELECT c_customer_sk FROM ranked WHERE profit_rank <= 10
        UNION ALL
        SELECT c_customer_sk FROM ranked WHERE total_net_paid > 500000
    ),
    low_returns AS (
        SELECT c_customer_sk FROM ranked WHERE total_return_amount < 1000
        INTERSECT
        SELECT c_customer_sk FROM ranked WHERE return_pct_rank < 0.2
    ),
    final_set AS (
        SELECT c_customer_sk FROM high_profit
        EXCEPT
        SELECT c_customer_sk FROM low_returns
    )
SELECT 
    r.rn,
    r.profit_rank,
    r.return_pct_rank,
    r.decile,
    r.c_customer_sk,
    r.full_name,
    r.total_net_paid,
    r.total_net_profit,
    r.total_return_amount,
    r.sales_return_flag,
    r.return_to_sales_ratio,
    (SELECT AVG(inner_r.total_net_paid) 
     FROM ranked inner_r 
     WHERE inner_r.sales_return_flag = r.sales_return_flag) AS avg_net_paid_same_flag,
    COALESCE(r.full_name, 'UNKNOWN') || '_' || CAST(r.rn AS VARCHAR) || '_' || CAST(FLOOR(r.total_net_paid) AS VARCHAR) AS unique_id,
    CASE 
        WHEN EXISTS (SELECT 1 FROM final_set f WHERE f.c_customer_sk = r.c_customer_sk) THEN 'INCLUDE' 
        ELSE 'EXCLUDE' 
    END AS final_inclusion_flag
FROM ranked r
WHERE r.rn <= 200
ORDER BY r.rn
