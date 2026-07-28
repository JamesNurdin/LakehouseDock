WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        cs_bill_customer_sk,
        cs_warehouse_sk,
        SUM(cs_net_profit)      AS total_cs_profit,
        SUM(cs_quantity)        AS total_cs_quantity
    FROM catalog_sales
    WHERE cs_net_profit > 0
      AND cs_quantity > 0
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_bill_customer_sk, cs_warehouse_sk
)
SELECT
    i.i_item_id,
    d_sales.d_year,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_vehicle_count,
    w.w_warehouse_name,
    cs_agg.total_cs_profit,
    ws.ws_net_paid_inc_tax,
    sr.sr_return_amt,
    RANK() OVER (
        PARTITION BY d_sales.d_year
        ORDER BY (
            cs_agg.total_cs_profit
            + COALESCE(ws.ws_net_paid_inc_tax, 0)
            - COALESCE(sr.sr_net_loss, 0)
        ) DESC
    ) AS profit_rank
FROM cs_agg
JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN customer c
    ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_sales
    ON cs_agg.cs_sold_date_sk = d_sales.d_date_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_sold_date_sk = d_sales.d_date_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_customer_sk = c.c_customer_sk
   AND sr.sr_returned_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 1904
  AND i.i_current_price > 100.00
  AND cd.cd_gender = 'M'
  AND hd.hd_vehicle_count >= 2
  AND w.w_gmt_offset = -5.00
  AND ws.ws_net_paid_inc_tax > 2000.00
  AND sr.sr_return_amt < 5000.00
  AND cs_agg.total_cs_profit > 500.00
ORDER BY d_sales.d_year, profit_rank
LIMIT 100
