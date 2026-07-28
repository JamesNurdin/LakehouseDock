WITH base AS (
   SELECT
       d.d_year,
       i.i_category,
       i.i_brand,
       i.i_color,
       ca.ca_state AS customer_state,
       s.s_state AS store_state,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       ws.ws_quantity,
       sr.sr_return_quantity,
       sr.sr_net_loss,
       wr.wr_return_quantity,
       wr.wr_net_loss,
       inv.inv_quantity_on_hand,
       ws.ws_sold_date_sk,
       ws.ws_sold_time_sk,
       ws.ws_item_sk,
       ws.ws_bill_customer_sk,
       ws.ws_web_site_sk
   FROM web_sales ws
   JOIN date_dim d
     ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t
     ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i
     ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c
     ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca
     ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN web_site wsite
     ON ws.ws_web_site_sk = wsite.web_site_sk
   LEFT JOIN store_returns sr
     ON sr.sr_item_sk = ws.ws_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
   LEFT JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN inventory inv
     ON inv.inv_item_sk = ws.ws_item_sk
        AND inv.inv_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr
     ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
   LEFT JOIN time_dim t2
     ON sr.sr_return_time_sk = t2.t_time_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND i.i_category = 'Sports'
     AND ca.ca_country = 'United States'
     AND wsite.web_state = 'CA'
     AND s.s_state = 'NY'
     AND inv.inv_quantity_on_hand > 0
)

SELECT
    d_year,
    i_category,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    COUNT(*) AS order_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
FROM base
GROUP BY ROLLUP (d_year, i_category)
HAVING SUM(ws_ext_sales_price) > 10000

UNION ALL

SELECT
    d_year,
    i_category,
    SUM(ws_ext_sales_price) * 0.9 AS total_sales,
    SUM(ws_net_profit) * 0.9 AS total_profit,
    COUNT(*) AS order_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
FROM base
WHERE i_color = 'Red'
GROUP BY CUBE (d_year, i_category)
HAVING SUM(ws_ext_sales_price) > 15000

ORDER BY d_year DESC, total_sales DESC
LIMIT 100
