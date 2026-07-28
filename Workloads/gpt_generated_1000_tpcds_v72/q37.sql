WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cr.cr_net_loss,
        i.i_category,
        i.i_brand,
        w.w_city AS warehouse_city,
        r.r_reason_desc,
        ss.ss_quantity AS store_quantity,
        ws.ws_quantity AS web_quantity
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss
        ON cs.cs_item_sk = ss.ss_item_sk
    LEFT JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    LEFT JOIN web_sales ws
        ON cs.cs_item_sk = ws.ws_item_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
)
SELECT
    i_category,
    i_brand,
    warehouse_city,
    r_reason_desc,
    SUM(cs_net_profit) AS total_sales_profit,
    SUM(cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cs_order_number) AS orders,
    CASE
        WHEN SUM(cr_net_loss) > 0 THEN 'Loss'
        ELSE 'Gain'
    END AS profit_status,
    AVG(store_quantity) AS avg_store_qty,
    AVG(web_quantity) AS avg_web_qty
FROM base
GROUP BY
    i_category,
    i_brand,
    warehouse_city,
    r_reason_desc
ORDER BY
    total_sales_profit DESC,
    i_category
