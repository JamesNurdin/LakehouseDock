WITH sales_detail AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cp.cp_catalog_page_number,
        cp.cp_type,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        inv.inv_quantity_on_hand,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cp.cp_type = 'monthly'
        AND cs.cs_net_paid_inc_ship_tax > 3000
        AND inv.inv_quantity_on_hand > 0
        AND cs.cs_ship_date_sk BETWEEN 2450840 AND 2450900
),
agg_sales AS (
    SELECT
        cp_catalog_page_number,
        cp_type,
        i_item_id,
        i_product_name,
        i_category,
        i_brand,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(CASE WHEN cs_net_profit > 0 THEN cs_net_profit ELSE 0 END) AS profit_component
    FROM sales_detail
    GROUP BY
        cp_catalog_page_number,
        cp_type,
        i_item_id,
        i_product_name,
        i_category,
        i_brand
)
SELECT
    a.cp_catalog_page_number,
    a.cp_type,
    a.i_item_id,
    a.i_product_name,
    a.i_category,
    a.i_brand,
    a.total_quantity,
    a.total_sales,
    a.total_profit,
    a.profit_component,
    ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.total_sales DESC) AS category_sales_rank,
    RANK() OVER (ORDER BY a.total_sales DESC) AS overall_sales_rank
FROM agg_sales a
ORDER BY overall_sales_rank
LIMIT 100
