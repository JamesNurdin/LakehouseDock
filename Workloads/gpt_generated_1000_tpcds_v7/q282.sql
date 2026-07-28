SELECT
    d.d_year,
    st.s_store_name,
    i.i_brand,
    cd.cd_gender,
    SUM(ss.ss_net_paid)               AS total_store_sales,
    SUM(cs.cs_net_paid)               AS total_catalog_sales,
    SUM(ws.ws_net_paid)               AS total_web_sales,
    SUM(wr.wr_net_loss)               AS total_web_returns_loss,
    AVG(inv.inv_quantity_on_hand)     AS avg_inventory_qty
FROM
    date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store st
    ON ss.ss_store_sk = st.s_store_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
-- second alias of date_dim for ship date of catalog sales
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
   AND inv.inv_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i2
    ON ws.ws_item_sk = i2.i_item_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site wsite
    ON wsite.web_open_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_order_number = ws.ws_order_number
GROUP BY
    d.d_year,
    st.s_store_name,
    i.i_brand,
    cd.cd_gender
ORDER BY
    d.d_year,
    st.s_store_name
