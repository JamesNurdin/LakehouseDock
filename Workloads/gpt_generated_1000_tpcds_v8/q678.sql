WITH orders_no_return AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
),
base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cp.cp_department,
        w.w_warehouse_name,
        t_sold.t_sub_shift,
        cd_bill.cd_gender,
        hd_bill.hd_income_band_sk,
        ib.ib_upper_bound,
        ws.ws_net_paid AS web_net_paid,
        ws.ws_sold_date_sk,
        ss.ss_ticket_number,
        sr.sr_reason_sk,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        ca.ca_state
    FROM catalog_sales cs
    JOIN orders_no_return nor ON cs.cs_order_number = nor.cs_order_number
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON cs.cs_item_sk = ws.ws_item_sk
    LEFT JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    LEFT JOIN (SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)) inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_time_sk = t_sold.t_time_sk
        AND ss.ss_item_sk = cs.cs_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cs.cs_quantity > 0
),
reason_tokens AS (
    SELECT
        b.cs_order_number,
        token
    FROM base b
    LEFT JOIN LATERAL (
        SELECT token
        FROM UNNEST(split(b.r_reason_desc, ' ')) AS t(token)
    ) lt ON true
    WHERE b.r_reason_desc IS NOT NULL
),
final AS (
    SELECT
        b.cp_department,
        b.w_warehouse_name,
        b.t_sub_shift,
        b.cd_gender,
        SUM(b.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT b.cs_order_number) AS distinct_orders,
        COUNT(DISTINCT b.inv_quantity_on_hand) AS distinct_inventory_qty,
        ARRAY_AGG(DISTINCT rt.token) FILTER (WHERE rt.token IS NOT NULL) AS reason_words
    FROM base b
    LEFT JOIN reason_tokens rt ON b.cs_order_number = rt.cs_order_number
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = b.ss_ticket_number
    )
    GROUP BY GROUPING SETS (
        (b.cp_department, b.w_warehouse_name, b.t_sub_shift, b.cd_gender),
        (b.cp_department, b.w_warehouse_name, b.t_sub_shift),
        (b.cp_department, b.w_warehouse_name),
        (b.cp_department)
    )
)
SELECT *
FROM final
ORDER BY total_net_profit DESC
LIMIT 100
