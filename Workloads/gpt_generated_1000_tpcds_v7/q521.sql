WITH filtered AS (
    SELECT
        cs.cs_quantity,
        cs.cs_net_profit,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        i.i_item_id,
        i.i_rec_start_date,
        i.i_brand_id,
        w.w_warehouse_name,
        w.w_state,
        w.w_gmt_offset,
        inv.inv_quantity_on_hand,
        ws.ws_quantity,
        ws.ws_net_profit
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE i.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
      AND i.i_brand_id = 1
      AND w.w_state = 'CA'
      AND w.w_gmt_offset = -5.00
      AND cd.cd_gender = 'M'
      AND cs.cs_net_profit > 500
      AND cs.cs_quantity >= 5
      AND ws.ws_quantity >= 10
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    cd_gender,
    i_item_id,
    w_warehouse_name,
    cs_net_profit,
    ws_net_profit,
    (cs_net_profit + ws_net_profit) AS total_net_profit,
    CASE WHEN (cs_net_profit + ws_net_profit) > 2000 THEN 'High' ELSE 'Low' END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY (cs_net_profit + ws_net_profit) DESC) AS rn_per_customer,
    RANK() OVER (ORDER BY (cs_net_profit + ws_net_profit) DESC) AS overall_rank
FROM filtered
ORDER BY total_net_profit DESC
LIMIT 100
