WITH catalog_part AS (
    SELECT
        cr.cr_returned_date_sk        AS returned_date_sk,
        ca.ca_state                  AS ca_state,
        d.d_year                     AS d_year,
        SUM(cr.cr_net_loss)          AS net_loss_sum,
        COUNT(*)                     AS return_cnt,
        CASE WHEN SUM(cr.cr_return_quantity) > 10 THEN 'HIGH' ELSE 'LOW' END AS qty_level,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(cr.cr_net_loss) DESC) AS rn_state
    FROM catalog_returns cr
    JOIN date_dim d          ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t          ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w         ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv       ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s             ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND t.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_quantity > 1
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 20
      AND s.s_market_id = 2
    GROUP BY cr.cr_returned_date_sk, ca.ca_state, d.d_year
),
web_part AS (
    SELECT
        wr.wr_returned_date_sk      AS returned_date_sk,
        ca.ca_state                  AS ca_state,
        d.d_year                     AS d_year,
        SUM(wr.wr_net_loss)          AS net_loss_sum,
        COUNT(*)                     AS return_cnt,
        CASE WHEN SUM(wr.wr_return_quantity) > 10 THEN 'HIGH' ELSE 'LOW' END AS qty_level,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(wr.wr_net_loss) DESC) AS rn_state
    FROM web_returns wr
    JOIN date_dim d          ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t          ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w         ON w.w_warehouse_sk = w.w_warehouse_sk  -- dummy join to include warehouse
    JOIN inventory inv       ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s             ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND t.t_hour BETWEEN 9 AND 17
      AND wr.wr_return_quantity > 1
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 20
      AND s.s_market_id = 2
    GROUP BY wr.wr_returned_date_sk, ca.ca_state, d.d_year
),
combined AS (
    SELECT * FROM catalog_part
    UNION DISTINCT
    SELECT * FROM web_part
),
final_set AS (
    SELECT * FROM combined
    EXCEPT
    SELECT returned_date_sk, ca_state, d_year, net_loss_sum, return_cnt, qty_level, rn_state
    FROM combined
    WHERE net_loss_sum < 0
)
SELECT
    returned_date_sk,
    ca_state,
    d_year,
    net_loss_sum,
    return_cnt,
    qty_level,
    rn_state
FROM final_set
ORDER BY net_loss_sum DESC
LIMIT 100
