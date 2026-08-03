WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d.d_date,
        t.t_hour,
        cd.cd_gender,
        cc.cc_name,
        sm.sm_type,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft
    FROM ship_mode sm
    RIGHT JOIN catalog_sales cs
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
)
SELECT
    sd.d_date,
    sd.t_hour,
    sd.cc_name,
    sd.sm_type,
    sd.w_warehouse_name,
    sd.w_warehouse_sq_ft,
    sd.cd_gender,
    sd.cs_quantity,
    sd.cs_ext_sales_price,
    sd.cs_net_paid,
    CASE WHEN sd.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    SUM(sd.cs_net_paid) OVER (PARTITION BY sd.sm_type ORDER BY sd.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
    LAG(sd.cs_ext_sales_price, 1) OVER (PARTITION BY sd.sm_type ORDER BY sd.d_date) AS prev_day_sales_price,
    ROW_NUMBER() OVER (PARTITION BY sd.sm_type ORDER BY sd.cs_net_paid DESC) AS rank_by_net_paid,
    wl.latest_sq_ft
FROM sales_data sd
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = sd.cs_sold_date_sk
LEFT JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sr.d_date_sk
CROSS JOIN LATERAL (
    SELECT w2.w_warehouse_sq_ft AS latest_sq_ft
    FROM warehouse w2
    WHERE w2.w_warehouse_id = sd.w_warehouse_id
    ORDER BY w2.w_warehouse_sq_ft DESC
    LIMIT 1
) wl
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_returned_date_sk = sd.cs_sold_date_sk
    )
  AND sd.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND sd.t_hour BETWEEN 8 AND 16
  AND sd.w_warehouse_sq_ft > 500000
  AND sd.cd_gender = 'M'
  AND sd.sm_type IS NOT NULL
ORDER BY sd.d_date DESC
LIMIT 100
