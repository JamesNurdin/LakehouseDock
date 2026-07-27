WITH all_data AS (
    SELECT
        d_sold.d_year AS year,
        i.i_brand AS brand,
        cp.cp_department AS department,
        cc.cc_name AS call_center_name,
        w.w_warehouse_name AS warehouse_name,
        p.p_promo_name AS promo_name,
        r.r_reason_desc AS return_reason,
        cs.cs_ext_sales_price AS catalog_sales_amount,
        ss.ss_ext_sales_price AS store_sales_amount,
        ws.ws_ext_sales_price AS web_sales_amount,
        sr.sr_return_amt AS store_return_amount,
        cs.cs_quantity AS catalog_qty,
        ss.ss_quantity AS store_qty,
        ws.ws_quantity AS web_qty,
        sr.sr_return_quantity AS return_qty
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    /* store sales linked by item and date */
    JOIN store_sales ss
      ON ss.ss_item_sk = cs.cs_item_sk
     AND ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_ss
      ON ss.ss_sold_time_sk = t_ss.t_time_sk
    /* store returns linked to the same store sale */
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    /* web sales linked by the same item and date */
    JOIN web_sales ws
      ON ws.ws_item_sk = cs.cs_item_sk
     AND ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t_ws
      ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN warehouse w_ws
      ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    WHERE d_sold.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
)
SELECT
    year,
    brand,
    department,
    SUM(catalog_sales_amount) AS total_catalog_sales,
    SUM(store_sales_amount)   AS total_store_sales,
    SUM(web_sales_amount)     AS total_web_sales,
    SUM(store_return_amount)  AS total_returns,
    COUNT(*)                  AS txn_count
FROM all_data
WHERE return_reason IS NOT NULL
GROUP BY year, brand, department
HAVING SUM(catalog_sales_amount) + SUM(store_sales_amount) + SUM(web_sales_amount) > 100000

UNION ALL

SELECT
    year,
    brand,
    department,
    SUM(catalog_sales_amount) AS total_catalog_sales,
    SUM(store_sales_amount)   AS total_store_sales,
    SUM(web_sales_amount)     AS total_web_sales,
    SUM(store_return_amount)  AS total_returns,
    COUNT(*)                  AS txn_count
FROM all_data
WHERE return_reason LIKE '%warranty%'
GROUP BY year, brand, department
HAVING SUM(store_return_amount) > 5000

ORDER BY total_catalog_sales DESC
LIMIT 100
