WITH base AS (
   SELECT
        ws.ws_sold_date_sk,
        d_s.d_year,
        i.i_category,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        w.w_state,
        p.p_discount_active,
        sm.sm_type,
        ca_bill.ca_country AS bill_country,
        s.s_store_name,
        sr.sr_return_quantity,
        wr.wr_return_quantity,
        inv.inv_quantity_on_hand,
        web.web_country,
        wp.wp_max_ad_count,
        w.w_warehouse_sk,
        i.i_item_sk
   FROM web_sales ws
   JOIN date_dim d_s ON ws.ws_sold_date_sk = d_s.d_date_sk
   JOIN time_dim t_s ON ws.ws_sold_time_sk = t_s.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
   JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   FULL OUTER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
   LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d_s.d_date_sk
   LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d_s.d_date_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_s.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d_s.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND w.w_state = 'TX'
     AND p.p_discount_active = 'Y'
     AND web.web_country = 'United States'
),
unnested AS (
   SELECT
       b.*,
       metric
   FROM base b
   CROSS JOIN UNNEST(ARRAY[b.ws_quantity, b.ws_ext_sales_price]) AS t(metric)
),
ranked AS (
   SELECT
       d_year,
       i_category,
       s_store_name,
       SUM(ws_ext_sales_price) AS total_sales,
       COUNT(*) AS txn_cnt,
       SUM(metric) OVER (PARTITION BY s_store_name ORDER BY ws_ext_sales_price
                         ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS moving_sum,
       ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS rn,
       -- scalar sub‑query counting inventory rows for the warehouse of the current row
       (SELECT COUNT(*) FROM inventory inv2 WHERE inv2.inv_warehouse_sk = w.w_warehouse_sk) AS warehouse_inv_cnt,
       CASE WHEN SUM(ws_ext_sales_price) > 20000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_level
   FROM unnested
   JOIN warehouse w ON w.w_warehouse_sk = unnested.w_warehouse_sk
   GROUP BY d_year, i_category, s_store_name, ws_ext_sales_price, ws_quantity, metric, w.w_warehouse_sk
   HAVING SUM(ws_ext_sales_price) > 10000
),
union_set AS (
   SELECT d_year, i_category, s_store_name, total_sales, rn FROM ranked WHERE rn <= 10
   UNION
   SELECT d_year, i_category, s_store_name, total_sales, rn FROM ranked WHERE total_sales BETWEEN 5000 AND 15000
)
SELECT *
FROM union_set
EXCEPT
SELECT d_year, i_category, s_store_name, total_sales, rn
FROM (
   SELECT d_year, i_category, s_store_name, total_sales, rn,
          CASE WHEN total_sales > 20000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_level
   FROM ranked
   WHERE sales_level = 'HIGH'
) high_sales
LIMIT 100
