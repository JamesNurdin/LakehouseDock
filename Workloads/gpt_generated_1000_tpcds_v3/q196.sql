WITH base AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        cc.cc_state,
        sm.sm_type,
        w.w_gmt_offset,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        ss.ss_quantity,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
           AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND w.w_gmt_offset > -5.00
      AND ib.ib_lower_bound >= 50000
      AND cs.cs_quantity > 5
      AND ss.ss_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM inventory i2
          WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
            AND i2.inv_quantity_on_hand > 1000
      )
),
agg AS (
    SELECT
        hd_demo_sk,
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        w_warehouse_sk,
        w_warehouse_name,
        SUM(cs_net_profit) AS total_catalog_profit,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(wr_net_loss) AS total_web_loss,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        (SELECT COUNT(DISTINCT inv_item_sk)
         FROM inventory inv2
         WHERE inv2.inv_warehouse_sk = w_warehouse_sk) AS distinct_item_count
    FROM base
    GROUP BY
        hd_demo_sk,
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        w_warehouse_sk,
        w_warehouse_name
    HAVING SUM(cs_ext_sales_price) > 10000
)
SELECT
    hd_demo_sk,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    w_warehouse_name,
    total_catalog_profit,
    total_store_profit,
    total_web_loss,
    CASE WHEN total_catalog_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS catalog_profit_status,
    distinct_item_count,
    RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_catalog_profit DESC) AS profit_rank_by_income_band
FROM agg
ORDER BY profit_rank_by_income_band, total_catalog_profit DESC
LIMIT 100
