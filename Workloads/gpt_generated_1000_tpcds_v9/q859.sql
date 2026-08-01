WITH catalog_agg AS (
    SELECT i.i_item_id,
           i.i_item_desc,
           SUM(cr.cr_return_amount) AS total_return_amount,
           SUM(ss.ss_ext_sales_price) AS total_sales_amount
    FROM call_center cc
    JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND i.i_current_price > 100
      AND ib.ib_lower_bound >= 5000
      AND inv.inv_quantity_on_hand > 10
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_id, i.i_item_desc
),
web_agg AS (
    SELECT i.i_item_id,
           i.i_item_desc,
           SUM(wr.wr_return_amt) AS total_return_amount,
           SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM web_sales ws
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    WHERE i.i_current_price > 150
      AND ib2.ib_upper_bound <= 20000
      AND td2.t_hour BETWEEN 10 AND 20
      AND sm2.sm_type = 'GROUND'
      AND cd2.cd_gender = 'F'
      AND w2.w_city = 'Seattle'
    GROUP BY i.i_item_id, i.i_item_desc
),
combined AS (
    SELECT i_item_id, i_item_desc, total_return_amount, total_sales_amount FROM catalog_agg
    UNION ALL
    SELECT i_item_id, i_item_desc, total_return_amount, total_sales_amount FROM web_agg
),
aggregated AS (
    SELECT i_item_id,
           i_item_desc,
           SUM(total_return_amount) AS total_return_amount,
           SUM(total_sales_amount) AS total_sales_amount,
           COUNT(*) AS source_rows
    FROM combined
    GROUP BY i_item_id, i_item_desc
    HAVING SUM(total_sales_amount) > 1000
),
final AS (
    SELECT a.i_item_id,
           a.i_item_desc,
           a.total_return_amount,
           a.total_sales_amount,
           a.total_sales_amount - a.total_return_amount AS net_gain,
           avg_price_sub.avg_price,
           RANK() OVER (ORDER BY a.total_sales_amount DESC) AS sales_rank
    FROM aggregated a
    LEFT JOIN LATERAL (
        SELECT AVG(i2.i_current_price) AS avg_price
        FROM item i2
        WHERE i2.i_item_id = a.i_item_id
    ) avg_price_sub ON TRUE
)
SELECT i_item_id,
       i_item_desc,
       total_return_amount,
       total_sales_amount,
       net_gain,
       avg_price,
       sales_rank
FROM final
ORDER BY sales_rank
LIMIT 100
