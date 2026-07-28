WITH base AS (
    SELECT
        d_ss.d_year,
        cc.cc_division_name,
        i.i_category,
        r.r_reason_desc,
        ws.web_name,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_ss.d_date_sk
                         AND cs.cs_bill_customer_sk = c.c_customer_sk
                         AND cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_ss.d_date_sk
                         AND wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ss.d_date_sk
    WHERE d_ss.d_year = 2001                     -- filter 1
      AND cc.cc_division_name IN ('anti', 'cally')   -- filter 2
      AND i.i_brand = 'Brand#12'                     -- filter 3
    GROUP BY GROUPING SETS (
        (d_ss.d_year, cc.cc_division_name, i.i_category, r.r_reason_desc, ws.web_name),
        (d_ss.d_year, cc.cc_division_name, i.i_category, r.r_reason_desc),
        (d_ss.d_year, cc.cc_division_name, i.i_category),
        (d_ss.d_year, cc.cc_division_name),
        (d_ss.d_year)
    )
)
SELECT
    d_year,
    cc_division_name,
    i_category,
    r_reason_desc,
    web_name,
    store_sales,
    catalog_sales,
    total_returns,
    distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY cc_division_name ORDER BY store_sales DESC) AS rn_division
FROM base
WHERE store_sales > 0
ORDER BY d_year DESC, store_sales DESC
LIMIT 100
