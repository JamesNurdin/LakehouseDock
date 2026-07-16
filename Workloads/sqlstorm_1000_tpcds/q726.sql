WITH date_range AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq,
           d_date
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2002
),
store_sales_by_category AS (
    SELECT ss.ss_store_sk,
           d.d_year,
           i.i_category,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_ext_discount_amt) AS total_discount,
           SUM(ss.ss_quantity) AS total_quantity,
           AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN date_range d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ss.ss_store_sk, d.d_year, i.i_category
),
store_sales_ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM store_sales_by_category
),
top_stores AS (
    SELECT *
    FROM store_sales_ranked
    WHERE sales_rank <= 5
),
web_sales_agg AS (
    SELECT ws.ws_web_page_sk,
           d.d_year,
           i.i_brand,
           SUM(ws.ws_ext_sales_price) AS web_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_range d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_web_page_sk, d.d_year, i.i_brand
),
web_sales_ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY web_sales DESC) AS wn
    FROM web_sales_agg
),
top_web_sales AS (
    SELECT *
    FROM web_sales_ranked
    WHERE wn <= 5
),
call_center_agg AS (
    SELECT d.d_year,
           SUM(cs.cs_ext_sales_price) AS cc_total_sales,
           AVG(cc.cc_tax_percentage) AS avg_cc_tax_percentage
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_range d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT
    ts.d_year,
    ts.i_category,
    ts.total_sales,
    ts.total_discount,
    ts.total_quantity,
    ts.avg_sales_price,
    ts.sales_rank,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.web_sales,
    ws.i_brand AS web_brand,
    ws.order_count,
    cc.cc_total_sales,
    cc.avg_cc_tax_percentage,
    CASE WHEN ts.sales_rank = 1 THEN 'Top Store' ELSE 'Other Store' END AS store_rank_label
FROM top_stores ts
LEFT JOIN store s ON ts.ss_store_sk = s.s_store_sk
LEFT JOIN top_web_sales ws ON ts.d_year = ws.d_year
LEFT JOIN call_center_agg cc ON ts.d_year = cc.d_year
WHERE ts.total_sales > 50000
ORDER BY ts.d_year, ts.sales_rank, ts.total_sales DESC
