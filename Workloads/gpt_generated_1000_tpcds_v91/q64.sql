WITH sales_agg AS (
    SELECT
        i.i_brand AS brand,
        d_sold.d_year AS year,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        CASE WHEN SUM(cs.cs_ext_discount_amt) > 1000 THEN 'High Discount' ELSE 'Low Discount' END AS discount_level
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
           AND inv.inv_warehouse_sk = w.w_warehouse_sk
           AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE i.i_brand = 'corpnameless #3'
      AND d_sold.d_year = 2001
      AND ib.ib_upper_bound > 50000
      AND EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_item_sk = i.i_item_sk
              AND sr.sr_returned_date_sk = d_sold.d_date_sk
              AND sr.sr_store_sk = s.s_store_sk
      )
      AND EXISTS (
            SELECT 1
            FROM web_sales ws
            WHERE ws.ws_sold_date_sk = d_sold.d_date_sk
              AND ws.ws_item_sk = i.i_item_sk
      )
    GROUP BY i.i_brand, d_sold.d_year
),
final_agg AS (
    SELECT
        year,
        AVG(total_profit) AS avg_profit,
        SUM(total_quantity) AS total_quantity_all_brands,
        CASE WHEN AVG(total_profit) > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_flag
    FROM sales_agg
    GROUP BY year
)
SELECT
    year,
    avg_profit,
    total_quantity_all_brands,
    profit_flag,
    ROW_NUMBER() OVER (ORDER BY avg_profit DESC) AS row_num
FROM final_agg
ORDER BY avg_profit DESC
LIMIT 100
