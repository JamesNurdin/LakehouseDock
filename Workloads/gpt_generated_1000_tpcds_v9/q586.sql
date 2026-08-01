WITH item_units AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_current_price,
           unit
    FROM item i
    CROSS JOIN UNNEST(split(i.i_units, ',')) AS t(unit)
),
store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_transactions,
        SUM(ss.ss_net_paid) AS total_sales_net_paid,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_returns_net_loss,
        SUM(ss.ss_net_paid) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_revenue,
        COUNT(DISTINCT iu.unit) AS distinct_units_sold
    FROM catalog_returns cr
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item_units iu
      ON cr.cr_item_sk = iu.i_item_sk
    JOIN inventory inv
      ON inv.inv_item_sk = iu.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim td_cr
      ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = iu.i_item_sk
    JOIN time_dim td_ss
      ON ss.ss_sold_time_sk = td_ss.t_time_sk
    JOIN "store" s
      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN time_dim td_sr
      ON sr.sr_return_time_sk = td_sr.t_time_sk
    WHERE EXISTS (
            SELECT 1
            FROM call_center cc
            WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
              AND cc.cc_employees > 5000000
              AND cc.cc_state = s.s_state
          )
      AND s.s_state = 'CA'
      AND iu.i_current_price BETWEEN 20 AND 200
      AND cd.cd_marital_status = 'M'
      AND ib.ib_upper_bound >= 50000
      AND td_ss.t_hour BETWEEN 9 AND 17
      AND inv.inv_quantity_on_hand > 0
      AND cr.cr_return_amount > 1000
    GROUP BY s.s_store_id, s.s_store_name, s.s_state
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    total_sales_transactions,
    total_sales_net_paid,
    total_returns_net_loss,
    net_revenue,
    distinct_units_sold,
    RANK() OVER (ORDER BY net_revenue DESC) AS revenue_rank
FROM store_agg
ORDER BY net_revenue DESC
LIMIT 100
