WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_addr_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_wholesale_cost,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ca.ca_state,
        d.d_year,
        i.i_brand,
        i.i_manager_id,
        ARRAY[cs.cs_sales_price, cs.cs_wholesale_cost] AS price_cost_arr
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND cs.cs_quantity > 5
      AND i.i_brand = 'Brand#23'
      AND cs.cs_net_paid > 0
)
SELECT
    d.d_date,
    i.i_item_id,
    cc.cc_name,
    SUM(sb.cs_net_paid) AS total_net_paid,
    AVG(sb.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT sb.cs_bill_addr_sk) AS distinct_customers,
    CASE WHEN SUM(sb.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    MAX(CASE WHEN u.idx = 1 THEN u.val END) AS sales_price,
    MAX(CASE WHEN u.idx = 2 THEN u.val END) AS wholesale_cost,
    (SELECT MAX(cr.cr_return_amount)
       FROM catalog_returns cr
      WHERE cr.cr_returned_date_sk = sb.cs_sold_date_sk) AS max_return_amount
FROM sales_base sb
JOIN date_dim d
    ON sb.cs_sold_date_sk = d.d_date_sk
JOIN item i
    ON sb.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON sb.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = sb.cs_order_number
   AND cr.cr_item_sk = sb.cs_item_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = sb.cs_item_sk
CROSS JOIN UNNEST(sb.price_cost_arr) WITH ORDINALITY AS u(val, idx)
WHERE wr.wr_fee > 50.00
  AND sb.cs_net_paid > (
        SELECT AVG(cr2.cr_return_amount)
          FROM catalog_returns cr2
         WHERE cr2.cr_returned_date_sk = sb.cs_sold_date_sk)
  AND EXISTS (
        SELECT 1
          FROM web_returns wr2
         WHERE wr2.wr_item_sk = sb.cs_item_sk
           AND wr2.wr_fee > 100)
GROUP BY
    d.d_date,
    i.i_item_id,
    cc.cc_name,
    sb.cs_sold_date_sk,
    sb.cs_item_sk,
    sb.cs_call_center_sk,
    sb.cs_bill_addr_sk
ORDER BY total_net_paid DESC
LIMIT 100
