SELECT
        s.s_store_name,
        i.i_category,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(sr.sr_return_amt) AS store_returns_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        SUM(wr.wr_return_amt) AS web_returns_total,
        SUM(inv.inv_quantity_on_hand) AS inventory_qty
FROM store_sales ss
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                     AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                  AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                    AND inv.inv_date_sk = d_ss.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_ss.d_date_sk
WHERE d_ss.d_year = 2001
  AND t_ss.t_hour BETWEEN 8 AND 10
  AND ss.ss_sales_price > 100
GROUP BY GROUPING SETS (
    (s.s_store_name, i.i_category),
    (s.s_store_name),
    (i.i_category),
    ()
)
ORDER BY s.s_store_name ASC, i.i_category ASC
LIMIT 100
