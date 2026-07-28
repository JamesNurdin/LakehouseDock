WITH sales_join AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        d.d_year,
        d.d_month_seq,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        sm.sm_type,
        cd.cd_gender,
        hd.hd_buy_potential,
        r.r_reason_desc,
        cp.cp_department,
        sr.sr_return_quantity,
        sr.sr_net_loss
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
       AND sr.sr_cdemo_sk = cd.cd_demo_sk
       AND sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
        OR cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 1915
      AND d.d_dow = 5
      AND ws.ws_quantity > 2
      AND ws.ws_net_profit > 0
      AND sm.sm_type = 'AIR'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'HIGH'
      AND r.r_reason_desc LIKE '%time%'
),
agg1 AS (
    SELECT
        d_year,
        cp_department,
        sm_type,
        CASE WHEN ws_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_flag,
        COUNT(DISTINCT ws_order_number) AS orders_cnt,
        SUM(ws_quantity) AS total_qty,
        SUM(ws_net_profit) AS total_profit,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_return_qty,
        SUM(COALESCE(sr_net_loss, 0)) AS total_return_loss
    FROM sales_join
    GROUP BY
        d_year,
        cp_department,
        sm_type,
        CASE WHEN ws_net_profit > 100 THEN 'High' ELSE 'Low' END
)
SELECT
    d_year,
    cp_department,
    sm_type,
    profit_flag,
    orders_cnt,
    total_qty,
    total_profit,
    total_return_qty,
    total_return_loss,
    total_profit / NULLIF(orders_cnt, 0) AS avg_profit_per_order
FROM agg1
WHERE total_profit > 500
ORDER BY total_profit DESC
LIMIT 100
