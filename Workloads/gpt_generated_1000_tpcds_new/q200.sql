WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_quantity) AS avg_quantity,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON i.i_item_sk = sr.sr_item_sk
        AND sr.sr_return_amt > 0
    WHERE cc.cc_state = 'TX'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451199
      AND cs.cs_quantity > 1
      AND cs.cs_net_profit > 0
      AND i.i_color = 'Red'
    GROUP BY
        cc.cc_call_center_id,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
inventory_lateral AS (
    SELECT
        s.cc_call_center_id,
        s.ib_income_band_sk,
        s.total_profit,
        s.sales_cnt,
        s.avg_quantity,
        s.total_return_amt,
        inv_sum.inv_quantity_on_hand
    FROM sales_agg s
    LEFT JOIN LATERAL (
        SELECT SUM(inv.inv_quantity_on_hand) AS inv_quantity_on_hand
        FROM inventory inv
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        WHERE i.i_color = 'Red'
          AND inv.inv_date_sk = 2450815
          AND s.sales_cnt > 0
    ) inv_sum ON TRUE
)
SELECT
    il.cc_call_center_id,
    il.ib_income_band_sk,
    il.total_profit,
    il.sales_cnt,
    il.avg_quantity,
    il.total_return_amt,
    il.inv_quantity_on_hand,
    (SELECT MAX(i_current_price) FROM item WHERE i_color = 'Red') AS max_red_item_price,
    CASE WHEN il.inv_quantity_on_hand > 0 THEN il.total_profit / il.inv_quantity_on_hand ELSE NULL END AS profit_per_stock
FROM inventory_lateral il
WHERE il.inv_quantity_on_hand IS NOT NULL
  AND il.total_profit > 1000
  AND il.sales_cnt >= 10
  AND il.avg_quantity <= 5
  AND (CASE WHEN il.inv_quantity_on_hand > 0 THEN il.total_profit / il.inv_quantity_on_hand ELSE NULL END) > 0.5
ORDER BY il.total_profit DESC
LIMIT 100
