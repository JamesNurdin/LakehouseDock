WITH store_sales_agg AS (
    SELECT ca.ca_state AS state,
           'store' AS sales_channel,
           SUM(ss.ss_net_paid) AS total_sales
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
),
web_sales_agg AS (
    SELECT ca.ca_state AS state,
           'web' AS sales_channel,
           SUM(ws.ws_net_paid) AS total_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
)
SELECT *
FROM store_sales_agg
UNION ALL
SELECT *
FROM web_sales_agg
ORDER BY total_sales DESC
