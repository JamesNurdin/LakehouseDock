/* goal: Summarize per‑item net revenue across web sites with demographic, inventory and return context, rank the top items per site, and exclude any sales that have a catalog return on the same date. */
WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_date_sk,
        ws.ws_net_paid_inc_tax,
        i.i_item_id,
        i.i_product_name,
        wsit.web_name,
        d_sold.d_year,
        d_sold.d_quarter_name,
        inv.inv_quantity_on_hand,
        cr.cr_return_quantity,
        wr.wr_return_quantity,
        cc.cc_name,
        ib_bill.ib_lower_bound,
        ib_bill.ib_upper_bound,
        item_sales.total_item_sales
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship
      ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
      ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN household_demographics hd_bill
      ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
      ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib_bill
      ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
         AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
         AND cr.cr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN date_dim d_cr
      ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr
      ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN date_dim d_cc_open
      ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    LEFT JOIN date_dim d_cc_closed
      ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
         AND wr.wr_item_sk = ws.ws_item_sk
         AND wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wr
      ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr
      ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN household_demographics hd_wr_refunded
      ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    LEFT JOIN household_demographics hd_wr_returning
      ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    LEFT JOIN income_band ib_wr_refunded
      ON hd_wr_refunded.hd_income_band_sk = ib_wr_refunded.ib_income_band_sk
    CROSS JOIN LATERAL (
        SELECT SUM(ws2.ws_net_paid_inc_tax) AS total_item_sales
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = ws.ws_item_sk
    ) AS item_sales
),
filtered AS (
    SELECT *
    FROM base b
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = b.ws_item_sk
          AND cr2.cr_returned_date_sk = b.ws_sold_date_sk
    )
),
agg AS (
    SELECT
        ws_order_number,
        i_item_id,
        i_product_name,
        web_name,
        d_year,
        d_quarter_name,
        SUM(ws_net_paid_inc_tax)               AS total_net_paid,
        SUM(inv_quantity_on_hand)               AS total_inventory,
        AVG(ib_lower_bound)                     AS avg_income_lower_bound,
        MAX(cc_name)                            AS call_center_name,
        MAX(total_item_sales)                   AS item_total_sales,
        SUM(cr_return_quantity)                 AS total_cr_return_quantity,
        SUM(wr_return_quantity)                AS total_wr_return_quantity
    FROM filtered
    GROUP BY
        ws_order_number,
        i_item_id,
        i_product_name,
        web_name,
        d_year,
        d_quarter_name
),
final AS (
    SELECT
        ws_order_number,
        i_item_id,
        i_product_name,
        web_name,
        d_year,
        d_quarter_name,
        total_net_paid,
        total_inventory,
        avg_income_lower_bound,
        call_center_name,
        item_total_sales,
        total_cr_return_quantity,
        total_wr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY web_name ORDER BY total_net_paid DESC) AS rn_site
    FROM agg
)
SELECT
    ws_order_number,
    i_item_id,
    i_product_name,
    web_name,
    d_year,
    d_quarter_name,
    total_net_paid,
    total_inventory,
    avg_income_lower_bound,
    call_center_name,
    item_total_sales,
    total_cr_return_quantity,
    total_wr_return_quantity,
    rn_site
FROM final
WHERE rn_site <= 5
ORDER BY total_net_paid DESC
LIMIT 100
