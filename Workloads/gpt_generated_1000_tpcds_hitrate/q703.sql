WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_addr_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_item_sk
    FROM catalog_sales cs
)
SELECT
    base.cs_order_number,
    base.cs_sales_price,
    base.cs_net_profit,
    cc.cc_name,
    w.w_warehouse_name,
    ca.ca_city,
    cd.cd_gender,
    r.r_reason_desc,
    s.s_store_name,
    ws.ws_net_paid,
    CASE WHEN base.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS quantity_category,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY base.cs_net_profit DESC) AS rn_profit,
    LAG(base.cs_net_profit) OVER (PARTITION BY cc.cc_call_center_id ORDER BY base.cs_order_number) AS prev_profit,
    SUM(base.cs_net_profit) OVER (
        PARTITION BY w.w_warehouse_id
        ORDER BY base.cs_order_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_profit,
    val AS expanded_val
FROM base
JOIN call_center cc
    ON base.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON base.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca
    ON base.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON base.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = base.cs_item_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN store_returns sr
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
CROSS JOIN UNNEST(ARRAY[base.cs_quantity, base.cs_sales_price]) AS t(val)
WHERE cc.cc_state = 'TX'
  AND w.w_state = 'TX'
  AND cd.cd_gender = 'M'
  AND base.cs_sold_date_sk BETWEEN 20000101 AND 20001231
  AND base.cs_sales_price > (
        SELECT MAX(cs2.cs_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = 20000101
    )
  AND cc.cc_call_center_sk NOT IN (
        SELECT sr2.sr_store_sk
        FROM store_returns sr2
    )
ORDER BY base.cs_net_profit DESC
LIMIT 100
