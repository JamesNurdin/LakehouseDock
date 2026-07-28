WITH sales_data AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ticket_number,
        i.i_brand,
        i.i_class,
        i.i_class_id,
        i.i_brand_id,
        cd.cd_gender
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_class_id = 5
      AND i.i_brand_id = 1003001
      AND ss.ss_ext_sales_price > 1000
)
SELECT
    sd.i_brand,
    sd.i_class,
    sd.cd_gender,
    SUM(sd.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    AVG(sd.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT sd.ss_ticket_number) AS distinct_tickets,
    MIN(sd.ss_ext_sales_price) AS min_sale,
    MAX(sd.ss_ext_sales_price) AS max_sale
FROM sales_data sd
JOIN catalog_returns cr
    ON cr.cr_item_sk = sd.ss_item_sk
   AND cr.cr_refunded_cdemo_sk = sd.ss_cdemo_sk
WHERE cr.cr_fee < 30
GROUP BY sd.i_brand, sd.i_class, sd.cd_gender
ORDER BY total_sales DESC
LIMIT 100
