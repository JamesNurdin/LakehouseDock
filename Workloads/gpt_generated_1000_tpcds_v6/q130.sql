WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d.d_date,
        d.d_year,
        i.i_category,
        i.i_category_id,
        i.i_units,
        cp.cp_type,
        cp.cp_department
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND i.i_category_id IN (5, 7, 8)
      AND cp.cp_type = 'A'
      AND i.i_units = 'Box'
      AND cs.cs_quantity > 0
),
returns_orders AS (
    SELECT DISTINCT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
)
SELECT
    sd.i_category,
    sd.i_category_id,
    SUM(sd.cs_net_paid) AS total_paid,
    SUM(sd.cs_net_profit) AS total_profit,
    COUNT(DISTINCT sd.cs_order_number) AS order_cnt,
    RANK() OVER (ORDER BY SUM(sd.cs_net_profit) DESC) AS profit_rank
FROM sales_data sd
WHERE sd.cs_order_number IN (SELECT cr_order_number FROM returns_orders)
GROUP BY sd.i_category, sd.i_category_id
ORDER BY profit_rank
LIMIT 100
