WITH sales_detail AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        t.t_hour,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        ca_bill.ca_city      AS bill_city,
        ca_bill.ca_state     AS bill_state,
        ca_ship.ca_city      AS ship_city,
        ca_ship.ca_state     AS ship_state,
        cd_bill.cd_gender    AS bill_gender,
        cd_ship.cd_gender    AS ship_gender,
        inv.inv_quantity_on_hand   AS inventory_qty,
        inv2.inv_quantity_on_hand  AS inventory_qty_alt,
        c_bill.c_customer_id AS bill_customer_id
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN inventory inv2
        ON inv2.inv_item_sk = i.i_item_sk
    WHERE i.i_category IN ('Sports', 'Books')
      AND cd_bill.cd_marital_status = 'M'
)
SELECT
    i_category,
    i_brand,
    bill_state,
    ship_state,
    COUNT(DISTINCT bill_customer_id)                     AS distinct_billing_customers,
    SUM(cs_ext_sales_price)                              AS total_sales,
    SUM(cs_net_profit)                                   AS total_profit,
    AVG(CASE WHEN cs_net_profit > 0 THEN cs_net_profit ELSE 0 END) AS avg_positive_profit,
    SUM(CASE WHEN inventory_qty > 0 THEN cs_quantity ELSE 0 END)   AS sold_when_stocked,
    SUM(CASE WHEN inventory_qty_alt = 0 THEN cs_quantity ELSE 0 END) AS sold_when_out_of_stock
FROM sales_detail
GROUP BY
    i_category,
    i_brand,
    bill_state,
    ship_state
ORDER BY total_profit DESC
LIMIT 100
