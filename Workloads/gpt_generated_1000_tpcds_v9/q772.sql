WITH base_data AS (
    SELECT
        ds.d_year AS sales_year,
        ca_bill.ca_state AS billing_state,
        w.w_warehouse_sk AS warehouse_sk,
        w.w_warehouse_name AS warehouse_name,
        cc.cc_name AS call_center_name,
        ws.web_name AS website_name,
        cs.cs_order_number AS order_number,
        cs.cs_net_profit AS net_profit,
        cr.cr_net_loss AS net_loss,
        inv.inv_quantity_on_hand AS inventory_qty,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        wp.wp_link_count AS wp_link_count
    FROM catalog_sales cs
    INNER JOIN date_dim ds
        ON cs.cs_sold_date_sk = ds.d_date_sk
    INNER JOIN time_dim ts
        ON cs.cs_sold_time_sk = ts.t_time_sk
    INNER JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    INNER JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    INNER JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = ds.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim dr
        ON cr.cr_returned_date_sk = dr.d_date_sk
    LEFT JOIN time_dim tr
        ON cr.cr_returned_time_sk = tr.t_time_sk
    LEFT JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    LEFT JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    LEFT JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    LEFT JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = ds.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = ds.d_date_sk
    LEFT JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN date_dim dco
        ON cc.cc_open_date_sk = dco.d_date_sk
    LEFT JOIN date_dim dcc
        ON cc.cc_closed_date_sk = dcc.d_date_sk
    WHERE ds.d_year = 2001
      AND ca_bill.ca_state = 'CA'
      AND wp.wp_link_count > 5
), agg_data AS (
    SELECT
        sales_year,
        billing_state,
        warehouse_name,
        call_center_name,
        website_name,
        warehouse_sk,
        SUM(net_profit) AS total_net_profit,
        SUM(net_loss) AS total_net_loss,
        SUM(inventory_qty) AS total_inventory,
        COUNT(DISTINCT order_number) AS distinct_orders
    FROM base_data
    GROUP BY ROLLUP (sales_year, billing_state, warehouse_name, call_center_name, website_name, warehouse_sk)
    HAVING SUM(net_profit) > 0
)
SELECT
    sales_year,
    billing_state,
    warehouse_name,
    call_center_name,
    website_name,
    total_net_profit,
    total_net_loss,
    total_inventory,
    distinct_orders,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_net_profit DESC) AS profit_rank,
    (SELECT AVG(cr2.cr_net_loss)
     FROM catalog_returns cr2
     WHERE cr2.cr_warehouse_sk = agg_data.warehouse_sk) AS avg_warehouse_return_loss,
    EXISTS (SELECT 1
            FROM catalog_returns crx
            WHERE crx.cr_warehouse_sk = agg_data.warehouse_sk
              AND crx.cr_net_loss > 0) AS has_positive_return_loss
FROM agg_data
ORDER BY total_net_profit DESC
LIMIT 100
