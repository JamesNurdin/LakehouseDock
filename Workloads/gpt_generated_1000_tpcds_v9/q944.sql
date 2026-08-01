WITH store_sales_agg AS (
    SELECT
        ss_sold_time_sk,
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ss_ext_tax) AS total_store_tax,
        COUNT(*) AS store_sales_cnt
    FROM store_sales
    WHERE ss_ext_tax > 10
      AND ss_ext_discount_amt < 2000
    GROUP BY ss_sold_time_sk, ss_customer_sk
),
order_intersect AS (
    SELECT cs.cs_order_number AS order_id
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt > 0
    INTERSECT
    SELECT ss.ss_ticket_number AS order_id
    FROM store_sales ss
    WHERE ss.ss_ext_sales_price > 0
),
joined_data AS (
    SELECT
        c_bill.c_customer_id,
        t.t_hour,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ssagg.total_store_sales,
        ssagg.total_store_tax,
        wr.wr_return_amt,
        wr.wr_fee
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN store_sales_agg ssagg
        ON ssagg.ss_sold_time_sk = t.t_time_sk
        AND ssagg.ss_customer_sk = c_ship.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_refunded_customer_sk = c_bill.c_customer_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND t.t_sub_shift = 'morning'
      AND cs.cs_wholesale_cost > 10
      AND EXISTS (SELECT 1 FROM order_intersect oi WHERE oi.order_id = cs.cs_order_number)
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_order_number = cs.cs_order_number
            AND wr2.wr_fee > 50
      )
)
SELECT
    c_customer_id,
    t_hour,
    SUM(total_store_sales) AS sum_store_sales,
    SUM(cs_ext_sales_price) AS sum_catalog_sales,
    SUM(cs_net_profit) AS sum_net_profit,
    AVG(wr_return_amt) AS avg_return_amount
FROM joined_data
GROUP BY c_customer_id, t_hour
HAVING SUM(total_store_sales) > 1000
ORDER BY sum_store_sales DESC
LIMIT 100
