WITH sales_detail AS (
   SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        d_sold.d_year,
        d_ship.d_month_seq,
        i.i_category,
        i.i_class_id,
        i.i_manager_id
   FROM catalog_sales cs
   JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
   JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
   LEFT JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
   WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    sd.d_year,
    sd.i_category,
    CASE WHEN sd.cs_quantity > 5 THEN 'bulk' ELSE 'regular' END AS quantity_type,
    SUM(sd.cs_ext_sales_price) AS total_sales,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(sd.cs_net_profit) AS total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY sd.i_category ORDER BY SUM(sd.cs_net_profit) DESC) AS profit_rank,
    latest_price.max_price
FROM sales_detail sd
LEFT JOIN web_returns wr
    ON sd.cs_item_sk = wr.wr_item_sk
   AND sd.cs_sold_date_sk = wr.wr_returned_date_sk
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN customer cust_refunded
    ON wr.wr_refunded_customer_sk = cust_refunded.c_customer_sk
CROSS JOIN LATERAL (
    SELECT MAX(i2.i_current_price) AS max_price
    FROM item i2
    WHERE i2.i_item_sk = sd.cs_item_sk
) AS latest_price
GROUP BY
    sd.d_year,
    sd.i_category,
    CASE WHEN sd.cs_quantity > 5 THEN 'bulk' ELSE 'regular' END,
    latest_price.max_price
ORDER BY total_sales DESC
LIMIT 100
