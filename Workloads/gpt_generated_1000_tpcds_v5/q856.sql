WITH filtered_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_cdemo_sk,
        ss_quantity,
        ss_ext_list_price,
        ss_ext_tax,
        ss_ext_discount_amt,
        ss_net_paid,
        ss_net_profit,
        ss_ticket_number
    FROM store_sales
    WHERE ss_ext_list_price > 2000
      AND ss_ext_tax < 50
      AND ss_quantity >= 1
)
SELECT
    i.i_category,
    cd.cd_credit_rating,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    SUM(ss.ss_net_paid) AS total_sales,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets,
    MIN(ss.ss_ext_tax) AS min_tax,
    MAX(ss.ss_ext_list_price) AS max_list_price
FROM filtered_sales ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE i.i_size = 'large'
  AND cd.cd_credit_rating = 'Good'
  AND cd.cd_purchase_estimate >= 5000
GROUP BY
    i.i_category,
    cd.cd_credit_rating,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
ORDER BY total_sales DESC
LIMIT 100
