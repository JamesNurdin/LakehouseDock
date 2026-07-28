WITH base AS (
   SELECT
       c.c_customer_id,
       d_sold.d_date AS sale_date,
       t_sold.t_time AS sale_time,
       i.i_item_id,
       i.i_product_name,
       CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
       sm.sm_type AS ship_type,
       ws_site.web_company_name,
       ws.ws_ext_sales_price AS line_sales,
       wr.wr_net_loss,
       r.r_reason_desc,
       (
           SELECT avg(inv2.inv_quantity_on_hand)
           FROM inventory inv2
           WHERE inv2.inv_item_sk = i.i_item_sk
       ) AS avg_qty_on_hand,
       c.c_customer_sk
   FROM web_sales ws
   JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
   JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
   JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
   WHERE d_sold.d_year = 2001
     AND sm.sm_type = 'AIR'
     AND r.r_reason_desc LIKE '%not%'
     AND i.i_current_price > 100
     AND NOT EXISTS (
         SELECT 1
         FROM web_returns wr2
         JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
         WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
           AND r2.r_reason_desc = 'Did not like the make'
     )
),
cust_totals AS (
   SELECT
       *,
       SUM(line_sales) OVER (PARTITION BY c_customer_id) AS total_sales_by_cust
   FROM base
)
SELECT
    c_customer_id,
    sale_date,
    sale_time,
    i_item_id,
    i_product_name,
    gender,
    ship_type,
    web_company_name,
    line_sales,
    wr_net_loss,
    r_reason_desc,
    avg_qty_on_hand,
    total_sales_by_cust,
    RANK() OVER (ORDER BY total_sales_by_cust DESC) AS sales_rank
FROM cust_totals
ORDER BY total_sales_by_cust DESC, c_customer_id
LIMIT 100
