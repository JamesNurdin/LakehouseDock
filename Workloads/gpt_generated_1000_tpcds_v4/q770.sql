WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_bill_cdemo_sk,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2455000
      AND cs_quantity > 0
      AND cs_net_profit > 0
    GROUP BY cs_item_sk, cs_catalog_page_sk, cs_ship_mode_sk, cs_bill_cdemo_sk
)
SELECT DISTINCT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    i.i_item_id,
    i.i_product_name,
    cp.cp_catalog_page_number,
    sm.sm_ship_mode_id,
    cd.cd_gender,
    sa.total_net_profit,
    sa.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY sa.total_net_profit DESC) AS profit_rank,
    CASE
        WHEN sa.total_quantity >= 500 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    sr.sr_return_quantity,
    sr.sr_return_amt
FROM sales_agg sa
JOIN item i ON sa.cs_item_sk = i.i_item_sk
JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE cp.cp_catalog_page_number > 5
  AND s.s_state = 'CA'
  AND i.i_rec_start_date <= DATE '2001-01-01'
ORDER BY s.s_store_id, profit_rank
LIMIT 100
