WITH ws_sample AS (
    SELECT *
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (5)
),
joined AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq,
        c.c_customer_sk,
        hd.hd_demo_sk,
        ca.ca_country,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_gmt_offset,
        p.p_promo_name,
        p.p_discount_active,
        cr.cr_catalog_page_sk,
        cp.cp_catalog_page_id,
        r_cr.r_reason_desc AS catalog_return_reason,
        sr.sr_store_sk,
        s.s_store_name,
        r_sr.r_reason_desc AS store_return_reason,
        inv_sum.inv_qty_on_day,
        (
            SELECT COUNT(DISTINCT c2.c_customer_sk)
            FROM tpcds.customer c2
            JOIN tpcds.web_sales ws2
                ON ws2.ws_bill_customer_sk = c2.c_customer_sk
            WHERE ws2.ws_promo_sk = ws.ws_promo_sk
              AND ws2.ws_sold_date_sk = ws.ws_sold_date_sk
        ) AS distinct_customers,
        EXISTS (
            SELECT 1
            FROM tpcds.catalog_returns cr2
            WHERE cr2.cr_returned_date_sk = ws.ws_sold_date_sk
              AND cr2.cr_catalog_page_sk IS NOT NULL
        ) AS has_catalog_return
    FROM ws_sample ws
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN LATERAL (
        SELECT SUM(inv.inv_quantity_on_hand) AS inv_qty_on_day
        FROM tpcds.inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
    ) AS inv_sum ON TRUE
    WHERE d.d_year = 1998
      AND hd.hd_vehicle_count >= 2
      AND ca.ca_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
),
aggregated AS (
    SELECT
        d_year,
        d_month_seq,
        p_promo_name,
        w_warehouse_name,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_profit) AS total_net_profit,
        CASE WHEN SUM(ws_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        SUM(inv_qty_on_day) AS total_inventory_qty,
        MAX(distinct_customers) AS distinct_customers,
        MAX(has_catalog_return) AS has_catalog_return
    FROM joined
    GROUP BY d_year, d_month_seq, p_promo_name, w_warehouse_name
)
SELECT
    d_year,
    d_month_seq,
    p_promo_name,
    w_warehouse_name,
    total_net_paid,
    total_net_profit,
    profit_category,
    total_inventory_qty,
    distinct_customers,
    has_catalog_return,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY d_year, profit_rank
LIMIT 100
