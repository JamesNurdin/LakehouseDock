WITH base AS (
    SELECT
        d_sold.d_year,
        i_sold.i_category,
        MIN(i_sold.i_brand) AS i_brand,
        SUM(cs.cs_net_paid) AS total_cs_net_paid,
        SUM(cr.cr_net_loss) AS total_cr_net_loss,
        SUM(ss.ss_net_profit) AS total_ss_profit,
        SUM(ws.ws_net_profit) AS total_ws_profit,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN item i_sold
        ON cs.cs_item_sk = i_sold.i_item_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w_cs
        ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    -- catalog returns
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_cr_ret
        ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
    JOIN time_dim t_cr_ret
        ON cr.cr_returned_time_sk = t_cr_ret.t_time_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN item i_cr
        ON cr.cr_item_sk = i_cr.i_item_sk
    -- store sales (joined via shared dimensions)
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
        AND ss.ss_item_sk = i_sold.i_item_sk
        AND ss.ss_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    -- inventory (same date, item, warehouse as catalog sales)
    JOIN inventory inv
        ON inv.inv_item_sk = i_sold.i_item_sk
        AND inv.inv_warehouse_sk = w_cs.w_warehouse_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    -- web sales
    JOIN web_sales ws
        ON ws.ws_order_number = cs.cs_order_number
    JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold
        ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN item i_ws
        ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    -- web returns
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_wr_ret
        ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
    JOIN time_dim t_wr_ret
        ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN item i_wr
        ON wr.wr_item_sk = i_wr.i_item_sk
    -- income band via household demographics
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_sold.d_year BETWEEN 1998 AND 2000
    GROUP BY GROUPING SETS (
        (d_sold.d_year, i_sold.i_category),
        (d_sold.d_year),
        (i_sold.i_category)
    )
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
    d_year,
    i_category,
    CASE WHEN i_brand = 'Brand#1' THEN 'A' ELSE 'B' END AS brand_group,
    total_cs_net_paid,
    total_cr_net_loss,
    total_ss_profit,
    total_ws_profit,
    total_inventory_qty,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_cs_net_paid DESC) AS rank_by_year
FROM base
ORDER BY d_year, rank_by_year
LIMIT 100
