WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        MIN(ws.ws_web_page_sk) AS web_page_sk
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wr.wr_reason_sk = r.r_reason_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND i.i_manager_id IN (64, 98)
      AND r.r_reason_desc LIKE '%Customer%'
    GROUP BY d.d_year, i.i_category, r.r_reason_desc
),
agg2 AS (
    SELECT
        b.d_year,
        SUM(b.total_catalog_return_amount) AS year_total_return,
        AVG(b.total_catalog_return_amount) AS year_avg_return,
        SUM(b.total_web_sales) AS year_total_sales,
        COUNT(*) AS category_cnt
    FROM base b
    GROUP BY b.d_year
)
SELECT
    b.d_year,
    b.i_category,
    b.r_reason_desc,
    b.total_catalog_return_amount,
    b.total_web_sales,
    b.total_inventory_qty,
    b.distinct_catalog_orders,
    b.distinct_web_orders,
    CASE WHEN b.total_catalog_return_amount > 10000 THEN 'High' ELSE 'Low' END AS return_level,
    a.year_total_return,
    a.year_avg_return,
    lt.distinct_page_types
FROM base b
JOIN agg2 a ON b.d_year = a.d_year
CROSS JOIN LATERAL (
    SELECT COUNT(DISTINCT wp2.wp_type) AS distinct_page_types
    FROM tpcds.web_page wp2
    WHERE wp2.wp_web_page_sk = b.web_page_sk
) lt
WHERE b.total_inventory_qty > 500
  AND a.year_avg_return > 5000
ORDER BY b.total_catalog_return_amount DESC
LIMIT 100
