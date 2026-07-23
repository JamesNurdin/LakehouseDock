/*
  Goal: Rank web sites (by name and state) according to the combined profit from catalog sales and store sales
  minus the net loss from web returns, for the year 2000, only for the AIR ship mode and the state of Colorado.
  The query joins all seven selected tables using only the permitted join keys, applies three filter predicates,
  uses COUNT(DISTINCT) to count unique order numbers, and adds a RANK window function on the computed total profit.
*/
WITH base AS (
    SELECT
        ws.web_name,
        ws.web_state,
        sm.sm_type,
        hd_bill.hd_income_band_sk,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM catalog_sales cs
    JOIN date_dim d_date
        ON cs.cs_sold_date_sk = d_date.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_date.d_date_sk
    JOIN household_demographics hd_store
        ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_date.d_date_sk
    JOIN household_demographics hd_refund
        ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_date.d_date_sk
    WHERE d_date.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND sm.sm_type = 'AIR'
      AND ws.web_state = 'CO'
    GROUP BY ws.web_name, ws.web_state, sm.sm_type, hd_bill.hd_income_band_sk
)
SELECT
    web_name,
    web_state,
    sm_type,
    hd_income_band_sk,
    distinct_orders,
    catalog_net_profit,
    store_net_profit,
    total_return_loss,
    (catalog_net_profit + store_net_profit - total_return_loss) AS total_profit,
    RANK() OVER (ORDER BY (catalog_net_profit + store_net_profit - total_return_loss) DESC) AS profit_rank
FROM base
ORDER BY total_profit DESC
LIMIT 100
