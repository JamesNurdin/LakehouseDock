WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    w.w_warehouse_name,
    cp.cp_department,
    cd.cd_gender,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_store_returnAmt,
    SUM(wr.wr_return_amt) AS total_web_returnAmt,
    SUM(ia.total_qty_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    AVG(cs.cs_quantity) AS avg_catalog_quantity,
    MIN(cs.cs_quantity) AS min_catalog_quantity,
    MAX(cs.cs_quantity) AS max_catalog_quantity
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN inv_agg ia
    ON ia.inv_item_sk = i.i_item_sk
    AND ia.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    i.i_brand = 'corpbrand #6'
    AND cd.cd_education_status = 'Advanced Degree'
    AND w.w_state = 'CA'
    AND i.i_rec_start_date >= DATE '2000-01-01'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    w.w_warehouse_name,
    cp.cp_department,
    cd.cd_gender
ORDER BY total_catalog_sales DESC
LIMIT 100
