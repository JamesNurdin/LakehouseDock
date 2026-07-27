WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        i.i_product_name,
        i.i_category,
        cp.cp_department,
        sm.sm_type,
        hd.hd_income_band_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        CASE
            WHEN cs.cs_net_profit > 0 THEN 'PROFIT'
            ELSE 'LOSS'
        END AS profit_flag
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_catalog_page_id = 'AAAAAAAABBAAAAAA'
      AND i.i_formulation LIKE '%goldenrod%'
      AND sm.sm_type = 'AIR'
      AND hd.hd_income_band_sk BETWEEN 3 AND 5
)
SELECT
    sa.cs_order_number,
    sa.i_product_name,
    sa.i_category,
    sa.cp_department,
    sa.sm_type,
    sa.profit_flag,
    ws.ws_quantity,
    ws.ws_net_paid,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    r.r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY sa.cs_order_number ORDER BY ws.ws_net_paid DESC) AS row_in_order,
    RANK() OVER (ORDER BY sa.cs_net_profit DESC) AS profit_rank
FROM sales_agg sa
JOIN web_sales ws
    ON sa.cs_item_sk = ws.ws_item_sk
JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE ws.ws_quantity > 1
  AND r.r_reason_desc LIKE '%damaged%'
ORDER BY profit_rank ASC, row_in_order ASC
LIMIT 100
