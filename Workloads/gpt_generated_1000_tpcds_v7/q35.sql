WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        cc.cc_name,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN tpcds.time_dim t ON t.t_time_sk = cs.cs_sold_time_sk
    JOIN tpcds.item i ON i.i_item_sk = cs.cs_item_sk
    JOIN tpcds.promotion p ON p.p_promo_sk = cs.cs_promo_sk
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.reason r ON r.r_reason_sk = sr.sr_reason_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND p.p_promo_name = 'Spring Sale'
      AND c.c_birth_year = 1965
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY d.d_year, i.i_category, cc.cc_name
)
SELECT
    d_year,
    i_category,
    cc_name,
    catalog_sales,
    web_sales,
    store_sales,
    total_returns,
    order_count,
    (catalog_sales + web_sales + store_sales) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (catalog_sales + web_sales + store_sales) DESC) AS sales_rank
FROM base
ORDER BY total_sales DESC
LIMIT 100
