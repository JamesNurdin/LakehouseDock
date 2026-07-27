WITH joined_data AS (
    SELECT
        i.i_category,
        i.i_brand,
        cd.cd_gender,
        cd.cd_marital_status,
        sm.sm_type,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        ss.ss_ext_sales_price,
        sr.sr_net_loss,
        inv.inv_quantity_on_hand,
        CASE WHEN cs.cs_ext_sales_price > 5000 THEN 'High' ELSE 'Low' END AS cs_price_level
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    WHERE cs.cs_ext_sales_price > 2000
      AND ws.ws_net_profit > 0
      AND cd.cd_marital_status = 'M'
      AND i.i_category = 'Sports'
)
SELECT
    i_category,
    i_brand,
    cd_gender,
    sm_type,
    cs_price_level,
    COUNT(*) AS transaction_cnt,
    SUM(cs_ext_sales_price) AS total_cs_sales,
    SUM(ws_ext_sales_price) AS total_ws_sales,
    SUM(ss_ext_sales_price) AS total_ss_sales,
    SUM(sr_net_loss) AS total_return_loss,
    SUM(CASE WHEN cs_price_level = 'High' THEN cs_ext_sales_price ELSE 0 END) AS high_price_sales,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
FROM joined_data
GROUP BY
    i_category,
    i_brand,
    cd_gender,
    sm_type,
    cs_price_level
ORDER BY total_cs_sales DESC
LIMIT 100
