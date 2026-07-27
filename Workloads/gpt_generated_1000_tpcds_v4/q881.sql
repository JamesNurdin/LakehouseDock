WITH sub_a AS (
  SELECT i.i_brand AS brand,
         cd.cd_gender AS gender,
         p.p_promo_name AS promo_name,
         cs.cs_ext_sales_price AS sales_amount,
         wr.wr_return_amt AS return_amount
  FROM tpcds.customer_demographics cd
  JOIN tpcds.catalog_sales cs
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
   AND p.p_item_sk = i.i_item_sk
  JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE cd.cd_marital_status = 'M'
    AND cd.cd_dep_count >= 2
    AND i.i_current_price BETWEEN 10 AND 1000
    AND p.p_discount_active = 'Y'
    AND inv.inv_quantity_on_hand < 500
    AND cs.cs_sold_date_sk BETWEEN 2451080 AND 2451100
    AND wr.wr_return_amt > 100
),
sub_b AS (
  SELECT i.i_brand AS brand,
         cd.cd_gender AS gender,
         p.p_promo_name AS promo_name,
         ss.ss_ext_sales_price AS sales_amount,
         wr.wr_return_amt AS return_amount
  FROM tpcds.customer_demographics cd
  JOIN tpcds.store_sales ss
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
   AND p.p_item_sk = i.i_item_sk
  JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE cd.cd_marital_status = 'M'
    AND cd.cd_dep_count >= 2
    AND i.i_current_price BETWEEN 10 AND 1000
    AND p.p_discount_active = 'Y'
    AND inv.inv_quantity_on_hand < 500
    AND ss.ss_ext_tax > 5.00
    AND wr.wr_return_amt > 100
)
SELECT brand,
       gender,
       promo_name,
       SUM(sales_amount) AS total_sales,
       SUM(return_amount) AS total_returns,
       COUNT(*) AS transaction_cnt,
       MIN(sales_amount) AS min_sale,
       MAX(sales_amount) AS max_sale
FROM (
  SELECT * FROM sub_a
  UNION ALL
  SELECT * FROM sub_b
) combined
GROUP BY brand, gender, promo_name
ORDER BY total_sales DESC
LIMIT 100
