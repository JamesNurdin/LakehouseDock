WITH item_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        sm.sm_type,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost > 10
      AND r.r_reason_desc LIKE '%damaged%'
      AND inv.inv_quantity_on_hand >= 100
    GROUP BY i.i_item_id, i.i_category, sm.sm_type
)
SELECT
    agg.i_item_id,
    agg.i_category,
    agg.sm_type,
    agg.total_sales,
    agg.total_profit,
    agg.order_cnt,
    agg.total_return_amt,
    RANK() OVER (PARTITION BY agg.i_category ORDER BY agg.total_sales DESC) AS rank_within_category,
    (SELECT COUNT(DISTINCT r_sub.r_reason_sk)
     FROM reason r_sub
     WHERE r_sub.r_reason_desc LIKE '%damaged%') AS damaged_reason_count
FROM item_sales_agg agg
WHERE agg.total_profit > 0
ORDER BY agg.total_sales DESC
LIMIT 100
