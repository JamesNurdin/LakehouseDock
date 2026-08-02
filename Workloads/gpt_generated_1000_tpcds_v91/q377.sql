WITH
    all_data AS (
        SELECT
            s.s_store_id,
            s.s_state,
            s.s_gmt_offset,
            d_sales.d_year,
            d_sales.d_date,
            t_sales.t_time,
            ss.ss_quantity,
            ss.ss_net_paid_inc_tax,
            ss.ss_ext_sales_price,
            ss.ss_net_profit,
            ws.ws_net_paid_inc_tax,
            ws.ws_ext_sales_price,
            ws.ws_net_profit,
            cr.cr_return_amount,
            cr.cr_net_loss,
            inv.inv_quantity_on_hand,
            w_ws.w_state,
            w_ws.w_gmt_offset,
            cd_ss.cd_gender,
            cd_ws_bill.cd_gender AS bill_customer_gender,
            cd_ws_ship.cd_gender AS ship_customer_gender,
            cd_cr_ref.cd_gender AS refunded_customer_gender,
            cd_cr_ret.cd_gender AS returning_customer_gender,
            ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid_inc_tax DESC) AS rn_store_sales
        FROM store s
        INNER JOIN store_sales ss
            ON ss.ss_store_sk = s.s_store_sk
        INNER JOIN date_dim d_sales
            ON ss.ss_sold_date_sk = d_sales.d_date_sk
        INNER JOIN time_dim t_sales
            ON ss.ss_sold_time_sk = t_sales.t_time_sk
        INNER JOIN customer_demographics cd_ss
            ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        LEFT JOIN web_sales ws
            ON ws.ws_sold_date_sk = d_sales.d_date_sk
        LEFT JOIN time_dim t_ws
            ON ws.ws_sold_time_sk = t_ws.t_time_sk
        LEFT JOIN web_site we
            ON ws.ws_web_site_sk = we.web_site_sk
        LEFT JOIN warehouse w_ws
            ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_warehouse_sk = w_ws.w_warehouse_sk
        LEFT JOIN date_dim d_cr
            ON cr.cr_returned_date_sk = d_cr.d_date_sk
        LEFT JOIN time_dim t_cr
            ON cr.cr_returned_time_sk = t_cr.t_time_sk
        LEFT JOIN customer_demographics cd_cr_ref
            ON cr.cr_refunded_cdemo_sk = cd_cr_ref.cd_demo_sk
        LEFT JOIN customer_demographics cd_cr_ret
            ON cr.cr_returning_cdemo_sk = cd_cr_ret.cd_demo_sk
        LEFT JOIN inventory inv
            ON inv.inv_warehouse_sk = w_ws.w_warehouse_sk
        LEFT JOIN date_dim d_inv
            ON inv.inv_date_sk = d_inv.d_date_sk
        LEFT JOIN date_dim d_closed
            ON s.s_closed_date_sk = d_closed.d_date_sk
        LEFT JOIN date_dim d_web_open
            ON we.web_open_date_sk = d_web_open.d_date_sk
        LEFT JOIN date_dim d_web_close
            ON we.web_close_date_sk = d_web_close.d_date_sk
        LEFT JOIN customer_demographics cd_ws_bill
            ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
        LEFT JOIN customer_demographics cd_ws_ship
            ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
        WHERE
            s.s_state = 'CA'                                     -- filter predicate 1
            AND d_sales.d_date BETWEEN DATE '1998-01-01' AND DATE '2002-12-31'   -- filter predicate 2
            AND w_ws.w_gmt_offset >= -5                         -- filter predicate 3
            AND cd_ss.cd_gender = 'F'                           -- additional filter predicate
    ),
    store_year_agg AS (
        SELECT
            s_store_id,
            d_year AS year,
            SUM(COALESCE(ss_net_paid_inc_tax, 0)) AS sum_store_sales,
            SUM(COALESCE(ws_net_paid_inc_tax, 0)) AS sum_web_sales,
            SUM(COALESCE(cr_return_amount, 0)) AS sum_returns,
            SUM(COALESCE(inv_quantity_on_hand, 0)) AS sum_inventory_qty
        FROM all_data
        GROUP BY s_store_id, d_year
    ),
    store_year_final AS (
        SELECT
            sy.s_store_id,
            sy.year,
            sy.sum_store_sales,
            sy.sum_web_sales,
            sy.sum_returns,
            sy.sum_inventory_qty,
            (sy.sum_store_sales + sy.sum_web_sales) - sy.sum_returns AS net_contribution,
            ROW_NUMBER() OVER (PARTITION BY sy.year ORDER BY sy.sum_store_sales DESC) AS rn_year,
            SUM(sy.sum_inventory_qty) OVER (PARTITION BY sy.year) AS total_inventory_year
        FROM store_year_agg sy
        WHERE sy.sum_store_sales > 5000
          AND sy.sum_store_sales > (
                SELECT AVG(ss2.ss_net_paid_inc_tax)
                FROM store_sales ss2
                JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
                WHERE d2.d_year = sy.year
          )
    ),
    store_filter_set AS (
        SELECT s.s_store_id FROM store s WHERE s.s_tax_percentage > 0.06
        UNION
        SELECT s.s_store_id FROM store s WHERE s.s_state IN ('TX', 'FL')
        EXCEPT
        SELECT s.s_store_id FROM store s WHERE s.s_gmt_offset < -6
    )
SELECT
    s_store_id,
    year,
    net_contribution,
    total_inventory_year
FROM store_year_final
WHERE rn_year <= 5
  AND s_store_id IN (SELECT s_store_id FROM store_filter_set)
ORDER BY net_contribution DESC
LIMIT 100
