WITH sales_pre AS (
    SELECT
        d.d_year,
        d.d_day_name,
        cp.cp_department,
        MAX(dy.max_date_in_year) AS max_date_in_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_returns,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
        SUM(ss.ss_ext_sales_price) / NULLIF(COUNT(DISTINCT ss.ss_item_sk), 0) AS avg_sales_per_item,
        MIN(ss.ss_item_sk) AS sample_item_sk
    FROM
        date_dim d
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN store_returns sr
            ON sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN catalog_returns cr
            ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT JOIN catalog_page cp
            ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
        JOIN web_page wp
            ON wp.wp_creation_date_sk = d.d_date_sk
        LEFT JOIN web_site ws
            ON ws.web_open_date_sk = d.d_date_sk
        CROSS JOIN LATERAL (
            SELECT MAX(d2.d_date) AS max_date_in_year
            FROM date_dim d2
            WHERE d2.d_year = d.d_year
        ) dy
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1200 AND 1300
        AND d.d_day_name = 'Wednesday'
        AND ss.ss_ext_list_price > 1000
        AND cr.cr_fee > 20
        AND ws.web_gmt_offset BETWEEN -5 AND 5
        AND d.d_fy_week_seq > 10
    GROUP BY ROLLUP (d.d_year, cp.cp_department, d.d_day_name)
),
sales_agg AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS yearly_sales_rank,
        (SELECT SUM(cr3.cr_return_amount)
         FROM catalog_returns cr3
         WHERE cr3.cr_item_sk = sp.sample_item_sk) AS total_item_returns_across_all_dates
    FROM sales_pre sp
)
SELECT
    d_year,
    cp_department,
    d_day_name,
    total_sales,
    total_profit,
    total_store_returns,
    total_catalog_returns,
    distinct_items_sold,
    avg_sales_per_item,
    yearly_sales_rank,
    total_item_returns_across_all_dates,
    PERCENT_RANK() OVER (PARTITION BY d_year ORDER BY total_sales) AS sales_percentile
FROM sales_agg sa
WHERE total_sales > (
    SELECT AVG(sa2.total_sales)
    FROM sales_agg sa2
    WHERE sa2.d_year = sa.d_year
)
ORDER BY total_sales DESC, d_year, cp_department
LIMIT 100
