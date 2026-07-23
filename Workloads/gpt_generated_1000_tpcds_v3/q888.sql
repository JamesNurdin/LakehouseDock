/*
  Goal: Compute net revenue per item for the year 2001 in the Electronics category, 
  accounting for web sales, store returns, and catalog returns. The query filters on 
  web site tax percentage, ranks items by net revenue, classifies revenue as Profit or Loss, 
  and returns the top 100 items.
*/
WITH
    ws_agg AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            i.i_category,
            d.d_year,
            we.web_tax_percentage,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_ext_discount_amt) AS total_discount,
            p.p_promo_name,
            we.web_name
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE d.d_year = 2001
          AND i.i_category = 'Electronics'
          AND we.web_tax_percentage > 0.05
        GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_category, d.d_year, we.web_tax_percentage, p.p_promo_name, we.web_name
    ),
    sr_agg AS (
        SELECT
            i.i_item_sk,
            d.d_year,
            SUM(sr.sr_return_amt) AS total_store_return
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        GROUP BY i.i_item_sk, d.d_year
    ),
    cr_agg AS (
        SELECT
            i.i_item_sk,
            d.d_year,
            SUM(cr.cr_return_amount) AS total_catalog_return
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
        JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        GROUP BY i.i_item_sk, d.d_year
    )
SELECT
    ws.i_item_id,
    ws.i_product_name,
    ws.i_category,
    ws.d_year,
    ws.total_sales,
    COALESCE(sr.total_store_return, 0) AS total_store_return,
    COALESCE(cr.total_catalog_return, 0) AS total_catalog_return,
    (ws.total_sales - COALESCE(sr.total_store_return, 0) - COALESCE(cr.total_catalog_return, 0)) AS net_revenue,
    CASE
        WHEN (ws.total_sales - COALESCE(sr.total_store_return, 0) - COALESCE(cr.total_catalog_return, 0)) < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status,
    RANK() OVER (PARTITION BY ws.d_year ORDER BY (ws.total_sales - COALESCE(sr.total_store_return, 0) - COALESCE(cr.total_catalog_return, 0)) DESC) AS revenue_rank,
    ws.web_name,
    ws.p_promo_name,
    ws.web_tax_percentage
FROM ws_agg ws
LEFT JOIN sr_agg sr ON ws.i_item_sk = sr.i_item_sk AND ws.d_year = sr.d_year
LEFT JOIN cr_agg cr ON ws.i_item_sk = cr.i_item_sk AND ws.d_year = cr.d_year
ORDER BY net_revenue DESC, ws.i_item_id
LIMIT 100
