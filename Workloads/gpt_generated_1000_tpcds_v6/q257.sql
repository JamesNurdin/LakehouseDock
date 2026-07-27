WITH sales_data AS (
    SELECT
        d_sold.d_year AS year,
        warehouse.w_warehouse_name AS warehouse_name,
        item.i_color AS item_color,
        call_center.cc_name AS call_center_name,
        SUM(catalog_sales.cs_ext_sales_price) AS total_sales,
        SUM(catalog_sales.cs_quantity) AS total_quantity,
        COALESCE(AVG(inventory.inv_quantity_on_hand), 0) AS avg_inventory_on_hand,
        CASE WHEN SUM(catalog_sales.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        0 AS total_returns
    FROM catalog_sales
    JOIN date_dim d_sold
        ON catalog_sales.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center
        ON catalog_sales.cs_call_center_sk = call_center.cc_call_center_sk
    JOIN warehouse
        ON catalog_sales.cs_warehouse_sk = warehouse.w_warehouse_sk
    JOIN item
        ON catalog_sales.cs_item_sk = item.i_item_sk
    JOIN customer_address
        ON catalog_sales.cs_bill_addr_sk = customer_address.ca_address_sk
    JOIN customer_demographics
        ON catalog_sales.cs_bill_cdemo_sk = customer_demographics.cd_demo_sk
    LEFT JOIN inventory
        ON inventory.inv_date_sk = d_sold.d_date_sk
        AND inventory.inv_item_sk = item.i_item_sk
        AND inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
    WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND warehouse.w_county = 'Richland County'
      AND item.i_color = 'purple'
    GROUP BY d_sold.d_year, warehouse.w_warehouse_name, item.i_color, call_center.cc_name
),
returns_data AS (
    SELECT
        d_ret.d_year AS year,
        warehouse.w_warehouse_name AS warehouse_name,
        item.i_color AS item_color,
        NULL AS call_center_name,
        0 AS total_sales,
        0 AS total_quantity,
        COALESCE(AVG(inventory.inv_quantity_on_hand), 0) AS avg_inventory_on_hand,
        CASE WHEN SUM(web_returns.wr_return_amt) > 0 THEN 'Return' ELSE 'NoReturn' END AS profit_flag,
        SUM(web_returns.wr_return_amt) AS total_returns
    FROM web_returns
    JOIN date_dim d_ret
        ON web_returns.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item
        ON web_returns.wr_item_sk = item.i_item_sk
    JOIN customer_address
        ON web_returns.wr_refunded_addr_sk = customer_address.ca_address_sk
    JOIN customer_demographics
        ON web_returns.wr_refunded_cdemo_sk = customer_demographics.cd_demo_sk
    LEFT JOIN inventory
        ON inventory.inv_date_sk = d_ret.d_date_sk
        AND inventory.inv_item_sk = item.i_item_sk
    LEFT JOIN warehouse
        ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
    WHERE d_ret.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND item.i_color = 'purple'
      AND warehouse.w_county = 'Richland County'
    GROUP BY d_ret.d_year, warehouse.w_warehouse_name, item.i_color
)
SELECT
    year,
    warehouse_name,
    item_color,
    COALESCE(call_center_name, 'N/A') AS call_center_name,
    total_sales,
    total_quantity,
    avg_inventory_on_hand,
    profit_flag,
    total_returns,
    (total_sales - COALESCE(total_returns, 0)) AS net_amount,
    RANK() OVER (PARTITION BY year ORDER BY (total_sales - COALESCE(total_returns, 0)) DESC) AS revenue_rank
FROM (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM returns_data
) AS combined
ORDER BY year, revenue_rank
