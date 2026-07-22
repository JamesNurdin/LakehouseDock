WITH base AS (
    SELECT
        st.s_store_id AS store_id,
        st.s_store_name AS store_name,
        st.s_state,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_brand_id,
        cp.cp_department AS department,
        td.t_hour,
        ss.ss_ext_sales_price AS store_sales_amount,
        cs.cs_ext_sales_price AS catalog_sales_amount,
        cr.cr_return_amount AS return_amount,
        inv.inv_quantity_on_hand AS inventory_qty,
        inv.inv_warehouse_sk,
        reason.r_reason_desc,
        ss.ss_sold_date_sk,
        cs.cs_sold_date_sk
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason
        ON cr.cr_reason_sk = reason.r_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND i.i_brand_id IN (6016006, 5003002)
        AND st.s_state = 'CA'
        AND inv.inv_warehouse_sk IN (1, 4)
        AND reason.r_reason_desc LIKE '%price%'
        AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2450948
)
SELECT
    store_id,
    store_name,
    item_id,
    product_name,
    department,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(catalog_sales_amount) AS total_catalog_sales,
    SUM(return_amount) AS total_returns,
    SUM(inventory_qty) AS total_inventory_qty,
    (SUM(store_sales_amount) + SUM(catalog_sales_amount) - COALESCE(SUM(return_amount), 0)) AS net_profit,
    RANK() OVER (
        PARTITION BY store_id
        ORDER BY (SUM(store_sales_amount) + SUM(catalog_sales_amount) - COALESCE(SUM(return_amount), 0)) DESC
    ) AS profit_rank
FROM base
GROUP BY
    store_id,
    store_name,
    item_id,
    product_name,
    department
ORDER BY net_profit DESC
LIMIT 100
