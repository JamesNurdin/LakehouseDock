WITH agg_sales AS (
    SELECT
        cs_sold_date_sk,
        cs_bill_addr_sk,
        SUM(cs_net_paid_inc_ship) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship > 0
    GROUP BY cs_sold_date_sk, cs_bill_addr_sk
)
SELECT
    d_sold.d_date AS sale_date,
    ca_bill.ca_state AS state,
    t_return.t_hour AS return_hour,
    agg_sales.total_sales,
    agg_sales.order_cnt,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(sr.sr_ticket_number) AS return_cnt,
    CASE WHEN agg_sales.total_sales > (SELECT AVG(total_sales) FROM agg_sales) THEN 'AboveAvg' ELSE 'BelowAvg' END AS sales_category,
    CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'HighReturn' ELSE 'LowReturn' END AS return_category
FROM agg_sales
JOIN date_dim d_sold
    ON agg_sales.cs_sold_date_sk = d_sold.d_date_sk
JOIN customer_address ca_bill
    ON agg_sales.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_sold.d_date_sk
    AND sr.sr_addr_sk = ca_bill.ca_address_sk
JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
WHERE d_sold.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
  AND t_return.t_hour BETWEEN 9 AND 17
  AND wp.wp_max_ad_count > 1
  AND ca_bill.ca_state = 'TX'
GROUP BY d_sold.d_date, ca_bill.ca_state, t_return.t_hour, agg_sales.total_sales, agg_sales.order_cnt
ORDER BY d_sold.d_date DESC, agg_sales.total_sales DESC
LIMIT 100
