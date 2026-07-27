WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_ship_mode_sk,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_item_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cd.cd_gender,
        sm.sm_type,
        d.d_year,
        inv.inv_quantity_on_hand,
        st.s_store_name,
        wp.wp_type
    FROM catalog_sales cs
    JOIN date_dim d                     ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c                     ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca            ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd       ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm                   ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws                   ON cs.cs_order_number = ws.ws_order_number
                                         AND ws.ws_sold_date_sk = d.d_date_sk
                                         AND ws.ws_bill_customer_sk = c.c_customer_sk
                                         AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr                ON ws.ws_order_number = wr.wr_order_number
                                         AND wr.wr_returned_date_sk = d.d_date_sk
                                         AND wr.wr_item_sk = ws.ws_item_sk
    JOIN inventory inv                  ON inv.inv_date_sk = d.d_date_sk
    JOIN store st                       ON st.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp                    ON ws.ws_web_page_sk = wp.wp_web_page_sk
                                         AND wp.wp_creation_date_sk = d.d_date_sk
)
SELECT
    d_year,
    ca_state,
    sm_type,
    cd_gender,
    COUNT(DISTINCT cs_order_number)                         AS distinct_orders,
    SUM(cs_net_paid)                                         AS total_catalog_sales,
    SUM(ws_net_paid)                                         AS total_web_sales,
    SUM(wr_return_amt)                                      AS total_returns_amount,
    AVG(CASE WHEN cs_quantity > 5 THEN cs_ext_discount_amt END) AS avg_large_order_discount,
    MAX(inv_quantity_on_hand)                               AS max_inventory_on_hand,
    MIN(s_store_name)                                       AS sample_store_name
FROM joined_data
WHERE
    d_year = 2001
    AND ca_state = 'CA'
    AND sm_type = 'AIR'
    AND cd_gender = 'F'
    AND ws_quantity > 2
GROUP BY
    d_year,
    ca_state,
    sm_type,
    cd_gender
ORDER BY
    total_catalog_sales DESC,
    distinct_orders DESC
LIMIT 100
