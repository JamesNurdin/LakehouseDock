WITH base_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ca.ca_state,
        ca.ca_city,
        ca.ca_suite_number,
        ca.ca_gmt_offset,
        cc.cc_name,
        cc.cc_employees,
        cc.cc_zip,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq = 12
        AND ca.ca_state = 'CA'
        AND ca.ca_suite_number = 'Suite 0'
        AND cc.cc_employees > 1000000
        AND cc.cc_zip = '41933'
        AND ss.ss_ext_sales_price > 500
        AND cs.cs_ext_sales_price > 1000
        AND sr.sr_return_quantity > 0
        AND ca.ca_gmt_offset = -5.00
),
agg_sales AS (
    SELECT
        d_year,
        ca_state,
        ca_city,
        cc_name,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(CASE WHEN sr_return_quantity > 0 THEN sr_return_amt ELSE 0 END) AS total_returns,
        AVG(cs_ext_sales_price) AS avg_catalog_sales,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM base_sales
    GROUP BY d_year, ca_state, ca_city, cc_name
    HAVING SUM(ss_ext_sales_price) > 10000
),
unioned AS (
    SELECT
        d_year,
        ca_state,
        ca_city,
        cc_name,
        total_store_sales,
        total_returns,
        avg_catalog_sales,
        distinct_tickets
    FROM agg_sales
    UNION ALL
    SELECT
        d_year,
        ca_state,
        ca_city,
        cc_name,
        total_store_sales * 0.9 AS total_store_sales,
        total_returns * 0.9 AS total_returns,
        avg_catalog_sales * 0.9 AS avg_catalog_sales,
        distinct_tickets
    FROM agg_sales
    WHERE ca_city = 'San Jose'
)
SELECT
    d_year,
    ca_state,
    ca_city,
    cc_name,
    total_store_sales,
    total_returns,
    avg_catalog_sales,
    distinct_tickets,
    RANK() OVER (PARTITION BY d_year ORDER BY total_store_sales DESC) AS sales_rank
FROM unioned
ORDER BY d_year DESC, total_store_sales DESC
LIMIT 100
