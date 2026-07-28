WITH sales_agg AS (
    SELECT
        ss_customer_sk,
        ss_store_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_ticket_number,
        SUM(ss_quantity) AS total_qty,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_sales_price) AS avg_sales_price
    FROM store_sales
    WHERE ss_store_sk IN (4, 88, 242)
      AND ss_ext_sales_price > 500
    GROUP BY ss_customer_sk, ss_store_sk, ss_sold_date_sk, ss_sold_time_sk, ss_ticket_number
),
returns_agg AS (
    SELECT
        sr_customer_sk,
        sr_store_sk,
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_ticket_number,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_rows
    FROM store_returns
    WHERE sr_return_amt > 100
      AND sr_return_quantity > 0
    GROUP BY sr_customer_sk, sr_store_sk, sr_returned_date_sk, sr_return_time_sk, sr_ticket_number
)
SELECT
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    ca.ca_city,
    cd.cd_gender,
    t_sales.t_hour AS sale_hour,
    SUM(sa.total_qty) AS total_quantity_sold,
    SUM(sa.total_sales) AS total_sales_amount,
    SUM(ra.total_return_qty) AS total_quantity_returned,
    SUM(ra.total_return_amt) AS total_return_amount,
    COUNT(DISTINCT ra.sr_ticket_number) AS distinct_return_tickets,
    (SELECT AVG(DISTINCT ss_ext_sales_price) FROM store_sales WHERE ss_store_sk = 4) AS avg_distinct_sales_price_store_4
FROM sales_agg sa
JOIN returns_agg ra
    ON sa.ss_ticket_number = ra.sr_ticket_number
JOIN customer cu
    ON sa.ss_customer_sk = cu.c_customer_sk
JOIN customer_address ca
    ON cu.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cu.c_current_cdemo_sk = cd.cd_demo_sk
JOIN time_dim t_sales
    ON sa.ss_sold_time_sk = t_sales.t_time_sk
JOIN time_dim t_return
    ON ra.sr_return_time_sk = t_return.t_time_sk
WHERE ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND t_sales.t_hour BETWEEN 9 AND 17
GROUP BY
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    ca.ca_city,
    cd.cd_gender,
    t_sales.t_hour
ORDER BY total_sales_amount DESC
LIMIT 100
