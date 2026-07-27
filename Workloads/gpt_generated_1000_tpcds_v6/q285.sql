WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_list_price,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cc.cc_name,
        w.w_warehouse_name,
        i.i_item_id,
        i.i_class,
        i.i_rec_start_date,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_list_price > 100
      AND cs.cs_sales_price BETWEEN 50 AND 200
      AND i.i_class IN ('shirts', 'sports-apparel')
      AND w.w_state = 'CA'
      AND cd.cd_education_status = 'Advanced Degree'
      AND i.i_rec_start_date >= DATE '1999-01-01'
)
SELECT
    fs.cc_name,
    fs.w_warehouse_name,
    fs.i_item_id,
    fs.i_class,
    fs.cd_education_status,
    fs.cs_order_number,
    fs.cs_net_profit,
    CASE
        WHEN (fs.cs_net_profit / NULLIF(fs.cs_sales_price, 0)) > 0.20 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY fs.cc_name ORDER BY fs.cs_net_profit DESC) AS profit_rank
FROM filtered_sales fs
ORDER BY profit_rank ASC, fs.cc_name
