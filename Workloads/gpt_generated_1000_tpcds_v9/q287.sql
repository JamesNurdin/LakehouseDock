WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ca_bill.ca_state,
        w_cs.w_country,
        p_cs.p_promo_name,
        p_cs.p_discount_active,
        TRIM(ch.channel) AS channel,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_net_profit,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        inv.inv_quantity_on_hand,
        hd_bill.hd_vehicle_count,
        ib.ib_lower_bound
    FROM tpcds.date_dim d
    -- Catalog Sales and related dimensions
    INNER JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    INNER JOIN tpcds.promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    -- Expand promotion channel details (comma‑separated string) into rows
    CROSS JOIN UNNEST(split(p_cs.p_channel_details, ',')) AS ch(channel)
    INNER JOIN tpcds.ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    INNER JOIN tpcds.warehouse w_cs
        ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w_cs.w_warehouse_sk
    INNER JOIN tpcds.household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN tpcds.income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN tpcds.customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    -- Store Sales and related dimensions
    INNER JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN tpcds.promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    LEFT JOIN tpcds.household_demographics hd_store
        ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    LEFT JOIN tpcds.customer_address ca_store
        ON ss.ss_addr_sk = ca_store.ca_address_sk
    -- Store Returns (joined to Store Sales)
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN tpcds.time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN tpcds.household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN tpcds.customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    -- Catalog Returns (joined to Catalog Sales)
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN tpcds.time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN tpcds.household_demographics hd_cr_refunded
        ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
    LEFT JOIN tpcds.customer_address ca_cr_refunded
        ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
    LEFT JOIN tpcds.household_demographics hd_cr_returning
        ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
    LEFT JOIN tpcds.customer_address ca_cr_returning
        ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
    LEFT JOIN tpcds.ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN tpcds.warehouse w_cr
        ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    -- Web Page and Web Site (joined via date_dim)
    LEFT JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND t_cs.t_hour BETWEEN 9 AND 17
        AND w_cs.w_country = 'United States'
        AND ca_bill.ca_state = 'CA'
        AND hd_bill.hd_vehicle_count >= 2
        AND ib.ib_lower_bound >= 50000
        AND p_cs.p_discount_active = 'Y'
        AND cs.cs_item_sk IN (
            SELECT inv_item_sk
            FROM tpcds.inventory
            WHERE inv_quantity_on_hand > 0
        )
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        ca_state,
        w_country,
        p_promo_name,
        channel,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        SUM(cs_net_paid) AS total_cs_net_paid,
        SUM(ss_net_paid) AS total_ss_net_paid,
        SUM(cr_return_amount) AS total_cr_return_amount,
        SUM(sr_return_amt) AS total_sr_return_amt,
        SUM(inv_quantity_on_hand) AS total_inventory_qty,
        AVG(cs_quantity) AS avg_cs_quantity,
        MAX(cs_net_profit) AS max_cs_net_profit,
        MIN(cs_net_profit) AS min_cs_net_profit
    FROM base
    GROUP BY
        d_year,
        d_month_seq,
        ca_state,
        w_country,
        p_promo_name,
        channel
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.ca_state,
    a.w_country,
    a.p_promo_name,
    a.channel,
    a.distinct_orders,
    a.total_cs_net_paid,
    a.total_ss_net_paid,
    a.total_cr_return_amount,
    a.total_sr_return_amt,
    a.total_inventory_qty,
    a.avg_cs_quantity,
    a.max_cs_net_profit,
    a.min_cs_net_profit,
    (
        SELECT COUNT(*)
        FROM tpcds.catalog_returns cr2
        JOIN tpcds.date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = a.d_year
    ) AS total_returns_in_year,
    RANK() OVER (ORDER BY a.total_cs_net_paid DESC) AS sales_rank,
    SUM(a.total_cs_net_paid) OVER (
        PARTITION BY a.ca_state
        ORDER BY a.d_year, a.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_state
FROM agg a
ORDER BY a.total_cs_net_paid DESC
LIMIT 100
