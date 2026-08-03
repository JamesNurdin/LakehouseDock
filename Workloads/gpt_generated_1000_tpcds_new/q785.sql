WITH cs_agg AS (
        SELECT cs.cs_bill_customer_sk AS cust_sk,
               SUM(cs.cs_ext_sales_price) AS total_cs_sales,
               COUNT(*) AS cnt_cs
        FROM tpcds.catalog_sales cs
        WHERE cs.cs_ext_sales_price > 1000
          AND cs.cs_sold_date_sk IN (
                SELECT d.d_date_sk
                FROM tpcds.date_dim d
                WHERE d.d_year = 2001
                  AND d.d_weekend = 'N'
          )
        GROUP BY cs.cs_bill_customer_sk
    ),
    ss_agg AS (
        SELECT ss.ss_customer_sk AS cust_sk,
               SUM(ss.ss_ext_sales_price) AS total_ss_sales,
               COUNT(*) AS cnt_ss
        FROM tpcds.store_sales ss
        WHERE ss.ss_ext_sales_price > 500
        GROUP BY ss.ss_customer_sk
    ),
    store_keys AS (
        SELECT DISTINCT ss.ss_store_sk AS store_sk
        FROM tpcds.store_sales ss
    ),
    combined AS (
        SELECT COALESCE(cs.cust_sk, ss.cust_sk) AS cust_sk,
               cs.total_cs_sales,
               ss.total_ss_sales
        FROM cs_agg cs
        FULL OUTER JOIN ss_agg ss
               ON cs.cust_sk = ss.cust_sk
    ),
    only_store_cust AS (
        SELECT cust_sk FROM ss_agg
        EXCEPT
        SELECT cust_sk FROM cs_agg
    ),
    web_site_year AS (
        SELECT ws.web_site_sk,
               ws.web_name,
               d.d_year
        FROM tpcds.web_site ws
        JOIN tpcds.date_dim d
          ON ws.web_open_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    )
SELECT
    c.c_customer_id,
    ca.ca_city,
    ca.ca_zip,
    s.s_store_name,
    cs.total_cs_sales,
    ss.total_ss_sales,
    ri.i_item_id,
    ri.i_product_name,
    lt.t_hour,
    lt.t_minute,
    ws.web_name AS web_site_name,
    latest_date.d_date AS latest_purchase_date,
    CASE WHEN EXISTS (
            SELECT 1
            FROM tpcds.web_returns wr
            JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
            WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
              AND r.r_reason_desc = 'Customer not satisfied'
        ) THEN 1 ELSE 0 END AS has_unsatisfied_return
FROM combined cs
JOIN ss_agg ss ON cs.cust_sk = ss.cust_sk
JOIN tpcds.customer c ON cs.cust_sk = c.c_customer_sk
JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store_keys sk ON TRUE
JOIN tpcds.store s ON sk.store_sk = s.s_store_sk
JOIN web_site_year ws ON TRUE
LEFT JOIN LATERAL (
        SELECT i.i_item_id,
               i.i_product_name
        FROM tpcds.catalog_sales cs2
        JOIN tpcds.item i ON cs2.cs_item_sk = i.i_item_sk
        WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
        ORDER BY cs2.cs_sold_date_sk DESC
        LIMIT 1
) AS ri ON TRUE
LEFT JOIN LATERAL (
        SELECT t.t_hour, t.t_minute
        FROM tpcds.catalog_sales cs3
        JOIN tpcds.time_dim t ON cs3.cs_sold_time_sk = t.t_time_sk
        WHERE cs3.cs_bill_customer_sk = c.c_customer_sk
        ORDER BY cs3.cs_sold_date_sk DESC
        LIMIT 1
) AS lt ON TRUE
LEFT JOIN LATERAL (
        SELECT d.d_date
        FROM tpcds.catalog_sales cs4
        JOIN tpcds.date_dim d ON cs4.cs_sold_date_sk = d.d_date_sk
        WHERE cs4.cs_bill_customer_sk = c.c_customer_sk
          AND d.d_year = 2001
        ORDER BY d.d_date DESC
        LIMIT 1
) AS latest_date ON TRUE
WHERE cs.total_cs_sales > (SELECT AVG(total_cs_sales) FROM cs_agg)
  AND ca.ca_zip = '63951'
  AND ca.ca_location_type = 'condo'
  AND cs.cust_sk IN (SELECT cust_sk FROM only_store_cust)
ORDER BY cs.total_cs_sales DESC,
         ss.total_ss_sales DESC
LIMIT 100
