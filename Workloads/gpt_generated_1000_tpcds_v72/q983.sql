WITH preferred_customers AS (
    SELECT c_customer_sk, c_customer_id
    FROM tpcds.customer
    WHERE c_preferred_cust_flag = 'Y'
)
SELECT
    cust_id,
    channel,
    total_net_paid,
    avg_channel_net_paid,
    rank() OVER (PARTITION BY channel ORDER BY total_net_paid DESC) AS channel_rank
FROM (
    -- Store channel sales
    SELECT
        pc.c_customer_id AS cust_id,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        (SELECT AVG(ss2.ss_net_paid) FROM tpcds.store_sales ss2) AS avg_channel_net_paid
    FROM tpcds.store_sales ss
    JOIN preferred_customers pc ON ss.ss_customer_sk = pc.c_customer_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_sales cs
          WHERE cs.cs_bill_customer_sk = pc.c_customer_sk
            AND cs.cs_net_profit > 1000
      )
    GROUP BY pc.c_customer_id
    UNION ALL
    -- Web channel sales
    SELECT
        pc.c_customer_id AS cust_id,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        (SELECT AVG(ws2.ws_net_paid) FROM tpcds.web_sales ws2) AS avg_channel_net_paid
    FROM tpcds.web_sales ws
    JOIN preferred_customers pc ON ws.ws_bill_customer_sk = pc.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_sales cs
          WHERE cs.cs_bill_customer_sk = pc.c_customer_sk
            AND cs.cs_net_profit > 1000
      )
    GROUP BY pc.c_customer_id
) AS combined_sales
WHERE total_net_paid > (
    SELECT AVG(total_net_paid)
    FROM (
        SELECT SUM(ss2.ss_net_paid) AS total_net_paid
        FROM tpcds.store_sales ss2
        JOIN preferred_customers pc2 ON ss2.ss_customer_sk = pc2.c_customer_sk
        GROUP BY pc2.c_customer_id
        UNION ALL
        SELECT SUM(ws2.ws_net_paid) AS total_net_paid
        FROM tpcds.web_sales ws2
        JOIN preferred_customers pc3 ON ws2.ws_bill_customer_sk = pc3.c_customer_sk
        GROUP BY pc3.c_customer_id
    ) agg
)
ORDER BY channel, channel_rank
LIMIT 100
