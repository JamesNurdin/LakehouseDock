WITH filtered_items AS (
    SELECT i_item_sk,
           i_category,
           i_item_desc,
           i_current_price
    FROM item
    WHERE regexp_like(i_item_desc, '[A-Z]{2}[0-9]{3}')
)
SELECT
    d.d_year,
    fi.i_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    ROUND(AVG(ss.ss_sales_price), 2) AS avg_sales_price,
    CONCAT('AvgPrice_', CAST(AVG(fi.i_current_price) AS VARCHAR)) AS avg_item_price_label,
    (SUM(ss.ss_net_profit) / (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2)) AS profit_vs_avg_ratio
FROM store_sales ss
JOIN filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE c.c_email_address LIKE '%@example.com'
  AND ca.ca_state LIKE 'CA%'
  AND d.d_year BETWEEN 2000 AND 2002
  AND EXISTS (
        SELECT 1
        FROM household_demographics hd
        WHERE ss.ss_hdemo_sk = hd.hd_demo_sk
          AND hd.hd_buy_potential = '5000-10000'
    )
GROUP BY d.d_year, fi.i_category
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 20
