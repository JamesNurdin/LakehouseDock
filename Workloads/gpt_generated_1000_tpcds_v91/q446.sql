WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_bill_customer_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_item_desc,
        cc.cc_state,
        cc.cc_name,
        w.w_warehouse_id,
        w.w_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        regexp_extract(i.i_item_id, '([0-9]+)', 1) AS item_id_num,
        CASE WHEN regexp_like(i.i_item_desc, '[0-9]{3}') THEN 1 ELSE 0 END AS desc_has_three_digits,
        substring(i.i_product_name, 1, 15) AS product_name_prefix
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(cc.cc_name, '^.*[0-9]{2}.*$')
      AND i.i_product_name LIKE '%Premium%'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          JOIN warehouse w2 ON inv.inv_warehouse_sk = w2.w_warehouse_sk
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
            AND w2.w_state = cc.cc_state
      )
),
agg_sales AS (
    SELECT
        cc_state,
        i_category,
        COUNT(DISTINCT cs_bill_customer_sk) AS distinct_customers,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        AVG(cs_ext_discount_amt) AS avg_discount,
        SUM(desc_has_three_digits) AS total_items_with_three_digits_desc,
        CASE WHEN SUM(cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM filtered_sales
    GROUP BY GROUPING SETS (
        (cc_state, i_category),
        (cc_state),
        (i_category),
        ()
    )
)
SELECT
    COALESCE(cc_state, 'ALL') AS cc_state,
    COALESCE(i_category, 'ALL') AS i_category,
    distinct_customers,
    total_quantity,
    total_net_paid,
    total_net_profit,
    avg_discount,
    total_items_with_three_digits_desc,
    profit_flag,
    (SELECT SUM(cs4.cs_net_profit)
     FROM catalog_sales cs4
     JOIN call_center cc4 ON cs4.cs_call_center_sk = cc4.cc_call_center_sk
     WHERE cc4.cc_state = agg_sales.cc_state) AS state_total_net_profit,
    RANK() OVER (PARTITION BY cc_state ORDER BY total_net_profit DESC) AS category_profit_rank
FROM agg_sales
ORDER BY cc_state, i_category
LIMIT 100
