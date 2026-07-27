SELECT
    ws.ws_web_site_sk,
    web_site.web_name,
    i.i_item_id,
    i.i_product_name,
    SUM(ws.ws_net_paid) AS total_net_paid,
    CASE WHEN SUM(ws.ws_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS revenue_level,
    RANK() OVER (PARTITION BY web_site.web_name ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
FROM
    catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
WHERE
    w.w_country = 'United States'
    AND w.w_gmt_offset = -5.00
    AND i.i_current_price BETWEEN 50 AND 500
    AND td.t_hour BETWEEN 9 AND 18
    AND r.r_reason_desc = 'Damaged'
    AND inv.inv_quantity_on_hand > 100
    AND ib.ib_upper_bound <= 50000
GROUP BY
    ws.ws_web_site_sk,
    web_site.web_name,
    i.i_item_id,
    i.i_product_name
ORDER BY
    web_site.web_name,
    sales_rank
LIMIT 100
