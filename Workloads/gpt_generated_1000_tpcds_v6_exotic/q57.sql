WITH
catalog_data AS (
    SELECT
        d_sold.d_year                      AS year,
        cc.cc_name                         AS call_center_name,
        'Catalog'                          AS source_type,
        SUM(cs.cs_net_paid) - COALESCE(SUM(cr.cr_return_amount), 0) AS net_sales,
        CASE
            WHEN SUM(cs.cs_net_paid) - COALESCE(SUM(cr.cr_return_amount), 0) > 100000 THEN 'High'
            ELSE 'Low'
        END                               AS sales_category
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_inv
        ON d_sold.d_date_sk = d_inv.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_inv.d_date_sk
    GROUP BY d_sold.d_year, cc.cc_name
),
web_data AS (
    SELECT
        d_ret.d_year                      AS year,
        ws.web_name                       AS web_site_name,
        'Web'                             AS source_type,
        SUM(wr.wr_return_amt)             AS net_sales,
        CASE
            WHEN SUM(wr.wr_return_amt) > 50000 THEN 'High'
            ELSE 'Low'
        END                               AS sales_category
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    GROUP BY d_ret.d_year, ws.web_name
)
SELECT
    year,
    source_type,
    net_sales,
    sales_category,
    ROW_NUMBER() OVER (PARTITION BY source_type ORDER BY net_sales DESC) AS rank
FROM (
    SELECT year, source_type, net_sales, sales_category FROM catalog_data
    UNION ALL
    SELECT year, source_type, net_sales, sales_category FROM web_data
) AS combined
ORDER BY net_sales DESC
LIMIT 100
