WITH sampled_item AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)
),

full_joined AS (
    SELECT inv.inv_item_sk,
           inv.inv_quantity_on_hand,
           i.i_item_sk,
           i.i_category,
           i.i_item_id
    FROM inventory inv
    FULL OUTER JOIN sampled_item i
        ON inv.inv_item_sk = i.i_item_sk
),

base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cp.cp_type AS catalog_page_type,
        i.i_category,
        i.i_item_id,
        c.c_customer_id,
        ca.ca_state,
        sm.sm_type,
        td.t_hour,
        cr.cr_return_amount,
        r.r_reason_desc,
        fj.inv_quantity_on_hand,
        ws.ws_order_number,
        ws.ws_net_paid AS ws_net_paid,
        wp.wp_type AS web_page_type,
        wr.wr_return_amt,
        CASE WHEN cs.cs_net_paid > 0 THEN 'Positive' ELSE 'Non‑positive' END AS net_paid_flag
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN sampled_item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN full_joined fj
        ON cs.cs_item_sk = fj.i_item_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
),

ranked AS (
    SELECT
        base.*,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY cs_net_profit DESC) AS rk
    FROM base
    WHERE
        i_category = 'Women'
        AND ca_state IN ('CA', 'NY', 'TX')
        AND sm_type = 'AIR'
        AND t_hour BETWEEN 9 AND 17
        AND inv_quantity_on_hand > 0
        AND cs_net_paid IS NOT NULL
)
SELECT
    cs_order_number,
    i_category,
    i_item_id,
    c_customer_id,
    ca_state,
    sm_type,
    t_hour,
    net_paid_flag,
    cs_net_profit,
    inv_quantity_on_hand,
    ws_net_paid,
    r_reason_desc,
    catalog_page_type,
    web_page_type,
    rk
FROM ranked
WHERE rk <= 5
ORDER BY i_category, rk
LIMIT 100
