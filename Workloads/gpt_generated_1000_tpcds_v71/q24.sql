/*
Goal: Identify the top customers by net sales (sales minus catalog and store returns) for each item, using data from all nine TPC‑DS tables. The query first joins the tables, applies several realistic filters, aggregates per customer‑item pair, then ranks the results by net sales.
*/
WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        i.i_item_id,
        i.i_brand,
        i.i_current_price,
        i.i_manufact_id,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        c.c_customer_id,
        c.c_email_address,
        d.d_date,
        d.d_year,
        wp.wp_url
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = i.i_item_sk
     AND cr.cr_call_center_sk = cc.cc_call_center_sk
     AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
     AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE
      sm.sm_ship_mode_id = 'AAAAAAAAIAAAAAAA'                 -- ship mode filter
      AND i.i_manufact_id IN (630, 169)                         -- manufacturer filter
      AND i.i_current_price > 2.00                              -- price filter
      AND c.c_email_address LIKE '%@be.org'                    -- email domain filter
      AND d.d_year = 2001                                       -- year filter
),
agg AS (
    SELECT
        c_customer_id,
        i_item_id,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cr_return_amount)   AS total_catalog_returns,
        SUM(sr_return_amt)      AS total_store_returns,
        COUNT(*)                AS trans_cnt
    FROM base
    GROUP BY c_customer_id, i_item_id
)
SELECT
    c_customer_id,
    i_item_id,
    total_sales,
    total_catalog_returns,
    total_store_returns,
    (total_sales - COALESCE(total_catalog_returns, 0) - COALESCE(total_store_returns, 0)) AS net_sales,
    trans_cnt,
    RANK() OVER (ORDER BY (total_sales - COALESCE(total_catalog_returns, 0) - COALESCE(total_store_returns, 0)) DESC) AS sales_rank
FROM agg
WHERE trans_cnt > 5                     -- only keep sufficiently active customer‑item pairs
ORDER BY net_sales DESC
LIMIT 100
