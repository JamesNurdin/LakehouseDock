WITH
    inv_agg AS (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory TABLESAMPLE BERNOULLI (10)
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    store_ret_agg AS (
        SELECT sr_item_sk,
               SUM(sr_return_amt_inc_tax) AS total_store_return
        FROM store_returns
        WHERE sr_return_amt_inc_tax > 0
        GROUP BY sr_item_sk
    ),
    web_ret_agg AS (
        SELECT wr_item_sk,
               wr_order_number,
               SUM(wr_return_amt) AS total_web_return
        FROM web_returns
        WHERE wr_return_amt > 0
        GROUP BY wr_item_sk, wr_order_number
    ),
    order_numbers AS (
        SELECT ws_order_number AS order_num FROM web_sales
        UNION
        SELECT cr_order_number AS order_num FROM catalog_returns
    ),
    order_numbers_excluded AS (
        SELECT order_num FROM order_numbers
        EXCEPT
        SELECT wr_order_number FROM web_returns
    )

SELECT
    d.d_year AS year,
    i.i_category AS group_key,
    SUM(ws.ws_ext_sales_price) AS total_amount,
    AVG(ws.ws_ext_sales_price) AS avg_amount,
    COUNT(DISTINCT ws.ws_order_number) AS cnt,
    SUM(COALESCE(inv_agg.total_qty, 0)) AS total_inventory
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk AND w.w_warehouse_sk = inv_agg.inv_warehouse_sk
LEFT JOIN store_ret_agg sr ON i.i_item_sk = sr.sr_item_sk
LEFT JOIN web_ret_agg wr ON i.i_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
WHERE d.d_year = 2001
  AND i.i_brand_id = 5
  AND p.p_discount_active = 'Y'
  AND wsit.web_country = 'United States'
  AND t.t_hour BETWEEN 9 AND 17
  AND ws.ws_quantity > 0
  AND ws.ws_bill_customer_sk NOT IN (
        SELECT c_customer_sk FROM customer WHERE c_preferred_cust_flag = 'Y'
    )
GROUP BY GROUPING SETS ((d.d_year, i.i_category), (d.d_year), (i.i_category))
HAVING SUM(ws.ws_ext_sales_price) > 1000

UNION DISTINCT

SELECT
    d.d_year AS year,
    cp.cp_department AS group_key,
    SUM(cr.cr_return_amount) AS total_amount,
    AVG(cr.cr_return_amount) AS avg_amount,
    COUNT(DISTINCT cr.cr_order_number) AS cnt,
    0 AS total_inventory
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND cp.cp_type = 'Catalog'
  AND r.r_reason_desc NOT LIKE '%gift%'
  AND w.w_state = 'CA'
  AND cr.cr_return_quantity > 0
  AND cr.cr_return_amount > 0
GROUP BY GROUPING SETS ((d.d_year, cp.cp_department), (d.d_year), (cp.cp_department))
HAVING SUM(cr.cr_return_amount) > 500

ORDER BY year DESC, total_amount DESC
OFFSET 10 LIMIT 100
