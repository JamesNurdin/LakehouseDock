WITH sales_detail AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        ca_bill.ca_country AS bill_country,
        ca_ship.ca_state AS ship_state,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date,
        t.t_hour,
        t.t_am_pm,
        inv.inv_quantity_on_hand,
        wp.wp_type,
        CASE WHEN cs.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM catalog_sales cs
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk AND inv.inv_item_sk = cs.cs_item_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND d_sold.d_month_seq BETWEEN 1200 AND 1212
      AND ca_bill.ca_country = 'United States'
      AND t.t_am_pm = 'PM'
      AND cs.cs_quantity > 5
),
unioned AS (
    SELECT
        sd.cs_order_number,
        sd.cs_sales_price,
        sd.cs_quantity,
        sd.profit_flag,
        sd.sold_date,
        sd.ship_date,
        sd.bill_country,
        sd.ship_state,
        sd.wp_type,
        ROW_NUMBER() OVER (PARTITION BY sd.cs_order_number ORDER BY sd.cs_sales_price DESC) AS rn,
        RANK() OVER (ORDER BY sd.cs_net_profit DESC) AS profit_rank
    FROM sales_detail sd
    WHERE sd.profit_flag = 'PROFIT'
    UNION DISTINCT
    SELECT
        sd.cs_order_number,
        sd.cs_sales_price,
        sd.cs_quantity,
        sd.profit_flag,
        sd.sold_date,
        sd.ship_date,
        sd.bill_country,
        sd.ship_state,
        sd.wp_type,
        ROW_NUMBER() OVER (PARTITION BY sd.cs_order_number ORDER BY sd.cs_sales_price ASC) AS rn,
        RANK() OVER (ORDER BY sd.cs_net_profit ASC) AS profit_rank
    FROM sales_detail sd
    WHERE sd.profit_flag = 'LOSS'
)
SELECT DISTINCT *
FROM (
    SELECT * FROM unioned
    EXCEPT
    SELECT cs_order_number,
           cs_sales_price,
           cs_quantity,
           profit_flag,
           sold_date,
           ship_date,
           bill_country,
           ship_state,
           wp_type,
           rn,
           profit_rank
    FROM unioned
    WHERE profit_flag = 'LOSS' AND cs_quantity < 10
) AS final_set
ORDER BY profit_rank ASC, cs_sales_price DESC
LIMIT 100
