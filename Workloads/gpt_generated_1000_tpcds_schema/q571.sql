WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- approximate 10% random sample
)
SELECT
    s.s_store_id,
    i.i_brand,
    cd.cd_gender,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_sales_price) AS avg_sales,
    SUM(sr.sr_refunded_cash) AS total_refunded,
    MIN(sr.sr_return_ship_cost) AS min_return_ship_cost,
    MAX(sr.sr_return_ship_cost) AS max_return_ship_cost
FROM sampled_sales ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_store_sk = s.s_store_sk
WHERE
    ca.ca_state = 'CA'
    AND i.i_brand_id = 2002002
    AND s.s_market_id = 9
GROUP BY
    s.s_store_id,
    i.i_brand,
    cd.cd_gender
HAVING
    SUM(ss.ss_ext_sales_price) > 10000
ORDER BY
    total_sales DESC
OFFSET 0 LIMIT 100
