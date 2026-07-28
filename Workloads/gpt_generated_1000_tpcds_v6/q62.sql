WITH sales_returns AS (
    SELECT
        w.w_warehouse_name,
        w.w_country,
        w.w_city,
        i.i_category,
        i.i_brand,
        c.c_preferred_cust_flag,
        c.c_birth_year,
        r.r_reason_desc,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wr.wr_return_amt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE w.w_country = 'United States'
      AND w.w_city IN ('Salem', 'Liberty', 'Greenwood')
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND i.i_brand = 'BrandX'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450250
      AND EXISTS (
          SELECT 1 FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
            AND inv.inv_quantity_on_hand > 0
      )
),
aggregated AS (
    SELECT
        warehouse_name,
        category,
        SUM(total_sales)   AS total_sales,
        SUM(total_profit)  AS total_profit,
        SUM(total_returns) AS total_returns
    FROM (
        SELECT
            w_warehouse_name AS warehouse_name,
            i_category       AS category,
            ws_ext_sales_price AS total_sales,
            ws_net_profit      AS total_profit,
            COALESCE(wr_return_amt, 0) AS total_returns
        FROM sales_returns
    ) sub
    GROUP BY ROLLUP (warehouse_name, category)
)
SELECT
    warehouse_name,
    category,
    total_sales,
    total_profit,
    total_returns,
    CASE
        WHEN warehouse_name IS NULL AND category IS NOT NULL THEN 'Category Total'
        WHEN warehouse_name IS NOT NULL AND category IS NULL THEN 'Warehouse Total'
        WHEN warehouse_name IS NULL AND category IS NULL THEN 'Grand Total'
        ELSE 'Detail'
    END AS row_type,
    RANK() OVER (PARTITION BY category ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY category, profit_rank, warehouse_name
LIMIT 100
