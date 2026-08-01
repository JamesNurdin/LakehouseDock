WITH avg_profit_by_category AS (
    SELECT i.i_category,
        AVG(cs.cs_net_profit) AS avg_category_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category
),

sales_with_details AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        dd.d_date,
        dd.d_year,
        td.t_hour,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cc.cc_name,
        cc.cc_country,
        cp.cp_catalog_page_number,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_class,
        i.i_size,
        inv.inv_quantity_on_hand,
        avg_prof.avg_category_profit
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = dd.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN avg_profit_by_category avg_prof ON i.i_category = avg_prof.i_category
    WHERE dd.d_year = 2001
      AND i.i_size = 'large'
      AND cc.cc_country = 'United States'
      AND td.t_hour BETWEEN 9 AND 17
      AND cs.cs_quantity > 5
)

SELECT
    s.c_customer_id,
    s.c_first_name,
    s.c_last_name,
    s.i_item_id,
    s.i_product_name,
    s.i_category,
    s.i_class,
    s.cs_quantity,
    s.cs_net_profit,
    s.avg_category_profit,
    ROW_NUMBER() OVER (PARTITION BY s.c_customer_id ORDER BY s.cs_net_profit DESC) AS rn_customer_profit,
    RANK() OVER (ORDER BY s.cs_net_profit DESC) AS overall_rank,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_order_number = s.cs_order_number
              AND cr.cr_return_quantity > 0
        ) THEN 'Has Return'
        ELSE 'No Return'
    END AS return_flag,
    (SELECT COUNT(DISTINCT i3.i_item_id)
        FROM item i3
        WHERE i3.i_size = 'large') AS total_distinct_large_items
FROM sales_with_details s
WHERE s.cs_net_profit > s.avg_category_profit
  AND s.inv_quantity_on_hand IS NOT NULL
  AND s.cs_net_profit > 0
  AND s.cs_ext_sales_price > 100
ORDER BY overall_rank
LIMIT 100
