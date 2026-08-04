WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cp.cp_department,
        w.w_warehouse_sq_ft,
        i.i_brand_id,
        i.i_item_id,
        d.d_year,
        d.d_month_seq,
        d.d_date
    FROM
        catalog_sales cs TABLESAMPLE BERNOULLI (10)
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        cp.cp_department = 'Electronics'
        AND w.w_warehouse_sq_ft > 500000
        AND i.i_brand_id IN (101, 102, 103)
        AND d.d_year = 2001
        AND cs.cs_quantity >= 2
        AND cs.cs_net_paid > 1000
),
exclusive_catalog_returns AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 500
    EXCEPT
    SELECT sr.sr_ticket_number AS order_number
    FROM store_returns sr
    WHERE sr.sr_return_amt > 500
)
SELECT
    b.cs_order_number,
    b.d_date,
    b.i_item_id,
    b.i_brand_id,
    b.cp_department,
    b.w_warehouse_sq_ft,
    b.cs_quantity,
    b.cs_net_paid,
    ws.ws_net_paid AS web_net_paid,
    wp.wp_url,
    site.web_name,
    RANK() OVER (PARTITION BY b.i_brand_id ORDER BY b.cs_net_paid DESC) AS brand_sales_rank
FROM
    base b
    JOIN exclusive_catalog_returns ecr ON b.cs_order_number = ecr.order_number
    JOIN web_sales ws ON ws.ws_item_sk = b.cs_item_sk
                     AND ws.ws_sold_date_sk = b.cs_sold_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
WHERE
    b.cs_quantity BETWEEN 2 AND 10
    AND b.w_warehouse_sq_ft < 800000
    AND b.d_month_seq = 1200
    AND ws.ws_net_paid > 2000
    AND wp.wp_type = 'Content'
    AND site.web_state = 'CA'
ORDER BY
    b.cs_net_paid DESC
LIMIT 100
