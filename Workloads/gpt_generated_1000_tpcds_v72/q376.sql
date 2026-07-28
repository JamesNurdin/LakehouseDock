WITH returns_agg AS (
    SELECT
        sr_ticket_number,
        sr_item_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_refunded_cash) AS total_refunded,
        COUNT(*) AS return_cnt,
        AVG(sr_reversed_charge) AS avg_rev_charge,
        COUNT(DISTINCT sr_customer_sk) AS distinct_customers
    FROM store_returns
    WHERE sr_return_amt > 5
      AND sr_return_tax < 50
      AND sr_store_credit >= 0
      AND sr_fee BETWEEN 0 AND 100
      AND sr_return_quantity >= 1
    GROUP BY sr_ticket_number, sr_item_sk
),
sales_agg AS (
    SELECT
        ss_ticket_number,
        ss_item_sk,
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_tax) AS total_tax,
        COUNT(*) AS sales_cnt,
        AVG(ss_list_price) AS avg_list_price
    FROM store_sales
    WHERE ss_ext_sales_price > 100
      AND ss_list_price >= 20
      AND ss_quantity BETWEEN 1 AND 10
      AND ss_ext_tax < 300
      AND ss_wholesale_cost <= 500
    GROUP BY ss_ticket_number, ss_item_sk, ss_store_sk
)
SELECT
    sa.ss_store_sk,
    ra.sr_item_sk,
    ra.total_return_amt,
    sa.total_sales,
    ra.return_cnt,
    sa.sales_cnt,
    CASE WHEN (sa.total_sales - ra.total_return_amt) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    ra.distinct_customers
FROM returns_agg ra
JOIN sales_agg sa
    ON ra.sr_ticket_number = sa.ss_ticket_number
   AND ra.sr_item_sk = sa.ss_item_sk
ORDER BY profit_status DESC, sa.total_sales DESC
LIMIT 100
