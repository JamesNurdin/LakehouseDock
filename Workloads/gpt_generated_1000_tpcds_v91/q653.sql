WITH sales_union AS (
    SELECT 
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        'sales' AS src,
        SUM(ss.ss_net_paid) AS metric_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
          AND EXISTS (
              SELECT 1
              FROM catalog_sales cs
              WHERE cs.cs_bill_customer_sk = ss.ss_customer_sk
                AND cs.cs_sold_date_sk = ss.ss_sold_date_sk
          )
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name

    UNION

    SELECT 
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        'returns' AS src,
        SUM(sr.sr_net_loss) AS metric_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
          AND EXISTS (
              SELECT 1
              FROM reason r
              WHERE r.r_reason_sk = sr.sr_reason_sk
                AND r.r_reason_desc LIKE '%damaged%'
          )
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name
)
SELECT 
    su.s_store_id,
    su.s_store_name,
    CASE 
        WHEN su.src = 'sales' THEN 'Total Sales'
        ELSE 'Total Returns'
    END AS metric_type,
    su.metric_amount,
    (
        SELECT COUNT(DISTINCT ss2.ss_customer_sk)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE ss2.ss_store_sk = su.s_store_sk
          AND d2.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    ) AS distinct_customers
FROM sales_union su
ORDER BY su.s_store_id, metric_type
