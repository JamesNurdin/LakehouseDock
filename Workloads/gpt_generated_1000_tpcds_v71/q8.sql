WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_division_name,
        cc.cc_state,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS txn_count,
        CASE WHEN SUM(cs.cs_ext_discount_amt) > 0 THEN 'Discounted' ELSE 'Full Price' END AS price_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_rec_start_date > DATE '2000-01-01'
      AND cc.cc_division_name IN ('able', 'anti')
      AND cc.cc_state = 'CA'
      AND cs.cs_warehouse_sk IN (4, 7, 15)
      AND cs.cs_promo_sk BETWEEN 400 AND 1500
      AND cs.cs_sold_date_sk > 2450800
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_division_name,
        cc.cc_state,
        cs.cs_warehouse_sk
)
SELECT
    cc_division_name,
    cc_state,
    cs_warehouse_sk,
    total_sales,
    total_net_profit,
    total_discount,
    txn_count,
    price_category,
    ROW_NUMBER() OVER (PARTITION BY cc_division_name ORDER BY total_net_profit DESC) AS warehouse_rank_in_division,
    RANK() OVER (ORDER BY total_net_profit DESC) AS overall_profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
