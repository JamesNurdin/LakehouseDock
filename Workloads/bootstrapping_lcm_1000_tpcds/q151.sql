SELECT 
    return_year,
    return_month_seq,
    s_state,
    s_market_desc,
    num_returns,
    num_sales,
    total_return_net_loss,
    total_sales_net_profit,
    total_sales_revenue,
    avg_dep_count_refunded,
    avg_vehicle_count_returning,
    avg_dep_count_bill,
    avg_vehicle_count_ship,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_return_net_loss DESC) AS rn_state_by_loss
FROM (
    SELECT 
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        s.s_state,
        s.s_market_desc,
        COUNT(DISTINCT r.cr_order_number) AS num_returns,
        COUNT(DISTINCT ws.ws_order_number) AS num_sales,
        SUM(r.cr_net_loss) AS total_return_net_loss,
        SUM(ws.ws_net_profit) AS total_sales_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales_revenue,
        AVG(hd_refunded.hd_dep_count) AS avg_dep_count_refunded,
        AVG(hd_returning.hd_vehicle_count) AS avg_vehicle_count_returning,
        AVG(hd_bill.hd_dep_count) AS avg_dep_count_bill,
        AVG(hd_ship.hd_vehicle_count) AS avg_vehicle_count_ship
    FROM catalog_returns r
    JOIN date_dim d_ret ON r.cr_returned_date_sk = d_ret.d_date_sk
    JOIN household_demographics hd_refunded ON r.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON r.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_ret.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    WHERE d_ret.d_year >= 2020
      AND s.s_state IS NOT NULL
    GROUP BY d_ret.d_year, d_ret.d_month_seq, s.s_state, s.s_market_desc
    HAVING SUM(r.cr_net_loss) > 0
) AS agg
ORDER BY total_return_net_loss DESC
LIMIT 100
