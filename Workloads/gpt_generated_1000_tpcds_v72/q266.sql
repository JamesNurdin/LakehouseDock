WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_item_sk,
        cs.cs_order_number,
        d.d_year,
        d.d_current_month,
        d.d_weekend,
        t.t_hour,
        sm.sm_type,
        i.i_brand,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_order_number AS ws_order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_current_month = 'Y'
      AND d.d_weekend = 'N'
      AND sm.sm_type = 'OVERNIGHT'
      AND inv.inv_quantity_on_hand > 800
      AND cs.cs_quantity > 2
      AND cs.cs_net_profit > 0
      AND ws.ws_quantity > 1
),
agg AS (
    SELECT
        d_year,
        i_brand,
        sm_type,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        SUM(cs_net_profit) AS total_profit,
        MIN(cs_order_number) AS min_order
    FROM base
    GROUP BY GROUPING SETS (
        (d_year, i_brand, sm_type),
        (d_year, i_brand),
        (d_year),
        ()
    )
)
SELECT
    agg.d_year,
    agg.i_brand,
    agg.sm_type,
    agg.total_net_paid,
    agg.sales_cnt,
    agg.total_profit,
    agg.total_net_paid / NULLIF(agg.sales_cnt, 0) AS avg_paid_per_sale,
    (
        SELECT AVG(cs_inner.cs_net_profit)
        FROM catalog_sales cs_inner
        JOIN date_dim d_inner ON cs_inner.cs_sold_date_sk = d_inner.d_date_sk
        WHERE d_inner.d_year = agg.d_year
    ) AS year_avg_profit
FROM agg
WHERE agg.total_net_paid > 1000
  AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_order_number = agg.min_order
          AND ws2.ws_net_profit < 0
    )
ORDER BY agg.total_net_paid DESC
LIMIT 100
