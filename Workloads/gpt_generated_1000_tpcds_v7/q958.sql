WITH sales_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_bill_addr_sk,
        SUM(cs.cs_ext_sales_price) AS sum_sales_price,
        SUM(cs.cs_quantity) AS sum_qty,
        AVG(cs.cs_net_profit) AS avg_profit
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_profit > 100
      AND cs.cs_wholesale_cost > 20
      AND cs.cs_list_price > 30
      AND cs.cs_ext_discount_amt < 10
      AND cs.cs_coupon_amt = 0
    GROUP BY cs.cs_warehouse_sk, cs.cs_item_sk, cs.cs_bill_addr_sk
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    i.i_brand,
    i.i_category,
    ca.ca_state,
    ca.ca_county,
    COUNT(DISTINCT s.cs_item_sk) AS distinct_items_sold,
    SUM(s.sum_sales_price) AS total_sales,
    SUM(s.sum_qty) AS total_quantity,
    AVG(s.avg_profit) AS avg_item_profit
FROM sales_agg s
JOIN tpcds.warehouse w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.item i
    ON s.cs_item_sk = i.i_item_sk
JOIN tpcds.customer_address ca
    ON s.cs_bill_addr_sk = ca.ca_address_sk
WHERE w.w_county = 'Bronx County'
  AND w.w_suite_number = 'Suite 160'
  AND i.i_brand_id = 5003002
  AND i.i_class_id IN (6, 2)
  AND ca.ca_state = 'CA'
  AND ca.ca_county = 'Richland County'
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    i.i_brand,
    i.i_category,
    ca.ca_state,
    ca.ca_county
HAVING SUM(s.sum_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
