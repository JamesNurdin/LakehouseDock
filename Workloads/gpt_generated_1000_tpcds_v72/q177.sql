WITH sales_join AS (
    SELECT
        cc.cc_division_name,
        i.i_category,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_tax,
        cs.cs_ext_list_price,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        i.i_current_price
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_division_name IN ('ought', 'pri', 'anti')
      AND cc.cc_rec_end_date = DATE '2001-12-31'
      AND hd.hd_income_band_sk >= 5
      AND hd.hd_vehicle_count >= 1
      AND i.i_current_price > 100
      AND cs.cs_ext_tax > 10
      AND cs.cs_ext_list_price < 20000
),
agg_by_div_cat AS (
    SELECT
        cc_division_name,
        i_category,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM sales_join
    GROUP BY cc_division_name, i_category
)
SELECT
    a.cc_division_name,
    a.i_category,
    a.total_profit,
    a.total_quantity,
    a.sales_cnt,
    o.avg_total_profit_overall
FROM agg_by_div_cat a
CROSS JOIN (
    SELECT AVG(total_profit) AS avg_total_profit_overall
    FROM agg_by_div_cat
) o
WHERE a.total_profit > o.avg_total_profit_overall * 0.8
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        JOIN call_center cc2 ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
        WHERE cc2.cc_division_name = a.cc_division_name
          AND cs2.cs_net_profit = 0
    )
ORDER BY a.total_profit DESC, a.cc_division_name
