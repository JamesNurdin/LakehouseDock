WITH ss_summary AS (
    SELECT
        ss.ss_item_sk,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ss.ss_quantity) AS store_quantity,
        MIN(ss.ss_customer_sk) AS example_cust_sk,
        MIN(ss.ss_hdemo_sk) AS example_hdemo_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_item_sk, d.d_year
),
ws_summary AS (
    SELECT
        ws.ws_item_sk,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        SUM(ws.ws_quantity) AS web_quantity,
        MIN(ws.ws_web_site_sk) AS example_site_sk,
        MIN(ws.ws_web_page_sk) AS example_page_sk,
        MIN(ws.ws_bill_customer_sk) AS example_bill_cust_sk,
        MIN(ws.ws_bill_hdemo_sk) AS example_bill_hdemo_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_item_sk, d.d_year
),
cr_summary AS (
    SELECT
        cr.cr_item_sk,
        d.d_year,
        SUM(cr.cr_return_amount) AS catalog_return_total,
        COUNT(*) AS return_cnt,
        MIN(cr.cr_catalog_page_sk) AS example_cp_sk,
        MIN(cr.cr_refunded_customer_sk) AS example_refund_cust_sk,
        MIN(cr.cr_refunded_hdemo_sk) AS example_refund_hdemo_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_item_sk, d.d_year
)
SELECT
    i.i_item_id,
    i.i_product_name,
    s.d_year,
    s.store_sales_total,
    w.web_sales_total,
    r.catalog_return_total,
    (s.store_sales_total + w.web_sales_total - r.catalog_return_total) AS net_sales,
    inv.inv_quantity_on_hand,
    cp.cp_department,
    wp.wp_url,
    ws.web_site_id,
    c.c_birth_month,
    hd.hd_buy_potential,
    i.i_current_price
FROM ss_summary s
JOIN ws_summary w
    ON s.ss_item_sk = w.ws_item_sk
   AND s.d_year = w.d_year
JOIN cr_summary r
    ON s.ss_item_sk = r.cr_item_sk
   AND s.d_year = r.d_year
JOIN item i
    ON s.ss_item_sk = i.i_item_sk
JOIN customer c
    ON s.example_cust_sk = c.c_customer_sk
JOIN household_demographics hd
    ON s.example_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
   AND d_inv.d_year = s.d_year
JOIN catalog_page cp
    ON r.example_cp_sk = cp.cp_catalog_page_sk
JOIN web_page wp
    ON w.example_page_sk = wp.wp_web_page_sk
JOIN web_site ws
    ON w.example_site_sk = ws.web_site_sk
WHERE s.d_year = 2000
  AND i.i_current_price > 20.00
  AND c.c_birth_month IN (1, 7)
  AND hd.hd_buy_potential = 'High'
  AND ws.web_gmt_offset = -5.00
ORDER BY net_sales DESC
LIMIT 100
