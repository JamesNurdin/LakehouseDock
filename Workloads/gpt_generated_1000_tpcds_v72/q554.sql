WITH sales_returns AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number        AS order_number,
        cs.cs_ext_sales_price      AS sales_price,
        cs.cs_net_profit           AS net_profit,
        cr.cr_return_amount        AS return_amount,
        d_sold.d_year               AS year,
        d_sold.d_month_seq          AS month_seq,
        cd.cd_gender                AS gender,
        cd.cd_marital_status        AS marital_status,
        p.p_promo_name              AS promo_name,
        p.p_discount_active        AS promo_discount_active,
        wp.wp_type                  AS page_type,
        wp.wp_char_count            AS page_char_count
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2000
      AND cd.cd_marital_status = 'M'
      AND p.p_discount_active = 'N'
)
SELECT
    year,
    month_seq,
    gender,
    COUNT(DISTINCT order_number)                         AS orders_cnt,
    SUM(sales_price)                                      AS total_sales,
    SUM(net_profit)                                       AS total_profit,
    SUM(return_amount)                                    AS total_return_amount,
    AVG(CASE WHEN sales_price > 5000 THEN sales_price END) AS avg_big_sale,
    SUM(sales_price) - SUM(return_amount)                 AS net_sales,
    RANK() OVER (PARTITION BY year ORDER BY SUM(sales_price) DESC) AS sales_rank
FROM sales_returns
GROUP BY year, month_seq, gender
ORDER BY net_sales DESC
LIMIT 100
