WITH base AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        d_sales.d_year,
        CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_flag,
        ss.ss_net_profit AS store_profit,
        sr.sr_net_loss AS return_loss,
        cs.cs_ext_sales_price AS catalog_sales_price,
        ws.ws_net_profit AS web_profit,
        inv.inv_quantity_on_hand AS inventory_qty,
        dc.distinct_customers
    FROM store s
    RIGHT JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w1
        ON cs.cs_warehouse_sk = w1.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN warehouse w2
        ON inv.inv_warehouse_sk = w2.w_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT count(DISTINCT ss2.ss_customer_sk) AS distinct_customers
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    ) dc
), agg AS (
    SELECT
        store_id,
        store_name,
        d_year,
        region_flag,
        SUM(store_profit) AS total_store_profit,
        SUM(return_loss) AS total_return_loss,
        SUM(catalog_sales_price) AS total_catalog_sales,
        SUM(web_profit) AS total_web_profit,
        MAX(inventory_qty) AS latest_inventory_qty,
        MAX(distinct_customers) AS distinct_customers
    FROM base
    GROUP BY
        store_id,
        store_name,
        d_year,
        region_flag,
        distinct_customers
), ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_store_profit DESC) AS rk
    FROM agg
)
SELECT
    store_id,
    store_name,
    d_year,
    region_flag,
    total_store_profit,
    total_return_loss,
    total_catalog_sales,
    total_web_profit,
    latest_inventory_qty,
    distinct_customers,
    rk
FROM ranked
WHERE rk <= 5
ORDER BY total_store_profit DESC, d_year
OFFSET 0 LIMIT 100
