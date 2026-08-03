WITH avg_discount AS (
    SELECT AVG(ss_ext_discount_amt) AS avg_disc
    FROM tpcds.store_sales
),
avg_sales_price AS (
    SELECT AVG(ss_ext_sales_price) AS avg_price
    FROM tpcds.store_sales
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    cd.cd_gender,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    RANK() OVER (PARTITION BY p.p_promo_id ORDER BY ss.ss_ext_sales_price DESC) AS sales_rank,
    CASE
        WHEN ss.ss_ext_discount_amt > (SELECT avg_disc FROM avg_discount) THEN 'High'
        ELSE 'Low'
    END AS discount_level
FROM tpcds.store_sales AS ss
RIGHT OUTER JOIN tpcds.promotion AS p
    ON ss.ss_promo_sk = p.p_promo_sk
INNER JOIN tpcds.item AS i
    ON ss.ss_item_sk = i.i_item_sk
INNER JOIN tpcds.customer AS c
    ON ss.ss_customer_sk = c.c_customer_sk
INNER JOIN tpcds.customer_demographics AS cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE i.i_class_id IN (1, 9, 12)
  AND i.i_formulation LIKE '%steel%'
  AND p.p_channel_email = 'N'
  AND cd.cd_marital_status = 'M'
  AND ss.ss_ext_sales_price > (SELECT avg_price FROM avg_sales_price)
LIMIT 100
