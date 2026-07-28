WITH agg AS (
    SELECT
        d_sold.d_year,
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_ext_sales_price)               AS store_sales_amount,
        SUM(cs.cs_ext_sales_price)               AS catalog_sales_amount,
        SUM(ws.ws_ext_sales_price)               AS web_sales_amount,
        SUM(wr.wr_return_amt)                   AS total_return_amount,
        COUNT(DISTINCT ws.ws_order_number)       AS web_orders
    FROM store_sales ss
    JOIN date_dim d_sold
      ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
      ON cs.cs_item_sk = i.i_item_sk
     AND cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d_sold.d_date_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_date_sk = d_sold.d_date_sk
     AND ws.ws_sold_time_sk = t_sold.t_time_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_bill_addr_sk = ca.ca_address_sk
     AND ws.ws_ship_customer_sk = c.c_customer_sk
     AND ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN promotion p2
      ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN ship_mode sm2
      ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse w2
      ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web
      ON ws.ws_web_site_sk = web.web_site_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
      ON wr.wr_returned_time_sk = t_ret.t_time_sk
    GROUP BY
        d_sold.d_year,
        s.s_store_name,
        i.i_category
)
SELECT
    d_year,
    s_store_name,
    i_category,
    store_sales_amount,
    catalog_sales_amount,
    web_sales_amount,
    CASE
        WHEN store_sales_amount > 0 THEN catalog_sales_amount / store_sales_amount
        ELSE NULL
    END                                           AS catalog_to_store_ratio,
    web_orders,
    total_return_amount,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
