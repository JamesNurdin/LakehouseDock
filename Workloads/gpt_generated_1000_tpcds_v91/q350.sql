WITH unioned AS (
    SELECT
        d.d_date AS sale_date,
        w.w_state AS warehouse_state,
        cd.cd_gender AS gender,
        hd.hd_buy_potential AS buy_potential,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        sm.sm_type AS ship_type,
        r.r_reason_desc AS return_reason,
        SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ws.ws_net_paid) AS web_sales_net_paid,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_returns_amount,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS store_returns_amount,
        inv_l.inv_qty_sum AS inventory_qty,
        (SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) - SUM(COALESCE(cr.cr_return_amount, 0)) - SUM(COALESCE(sr.sr_return_amt, 0))) AS net_total
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    CROSS JOIN LATERAL (
        SELECT SUM(inv_quantity_on_hand) AS inv_qty_sum
        FROM inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
    ) AS inv_l
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND hd.hd_buy_potential = '1001-5000'
      AND sm.sm_type = 'AIR'
      AND cs.cs_quantity > 10
      AND ws.ws_ext_discount_amt > 500
    GROUP BY
        d.d_date,
        w.w_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_type,
        r.r_reason_desc,
        inv_l.inv_qty_sum

    UNION

    SELECT
        d.d_date AS sale_date,
        w.w_state AS warehouse_state,
        cd.cd_gender AS gender,
        hd.hd_buy_potential AS buy_potential,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        sm.sm_type AS ship_type,
        r.r_reason_desc AS return_reason,
        SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ws.ws_net_paid) AS web_sales_net_paid,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_returns_amount,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS store_returns_amount,
        inv_l.inv_qty_sum AS inventory_qty,
        (SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) - SUM(COALESCE(cr.cr_return_amount, 0)) - SUM(COALESCE(sr.sr_return_amt, 0))) AS net_total
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    CROSS JOIN LATERAL (
        SELECT SUM(inv_quantity_on_hand) AS inv_qty_sum
        FROM inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
    ) AS inv_l
    WHERE d.d_year = 2002
      AND w.w_state = 'NY'
      AND hd.hd_buy_potential = '0-500'
      AND sm.sm_type = 'RAIL'
      AND cs.cs_quantity > 5
      AND ws.ws_ext_discount_amt > 200
    GROUP BY
        d.d_date,
        w.w_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_type,
        r.r_reason_desc,
        inv_l.inv_qty_sum
)
SELECT
    sale_date,
    warehouse_state,
    gender,
    buy_potential,
    income_lower,
    income_upper,
    ship_type,
    return_reason,
    catalog_sales_net_paid,
    store_sales_net_paid,
    web_sales_net_paid,
    catalog_returns_amount,
    store_returns_amount,
    inventory_qty,
    net_total,
    RANK() OVER (PARTITION BY warehouse_state ORDER BY net_total DESC) AS state_rank,
    SUM(net_total) OVER (PARTITION BY warehouse_state ORDER BY sale_date ROWS UNBOUNDED PRECEDING) AS cumulative_net_total
FROM unioned
ORDER BY sale_date DESC, warehouse_state
LIMIT 100
