-- Goal: Rank items by combined store and web net paid within each brand, filtered by product attributes, sales amounts, tax, date and customer demographics, and classify performance relative to the overall average.
WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand_id,
        i.i_units,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_brand_id IN (6008007, 3002001, 5002002)
      AND i.i_units IN ('Box', 'Carton')
      AND ss.ss_ext_sales_price BETWEEN 1000 AND 5000
      AND ws.ws_ext_tax > 20
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY i.i_item_sk, i.i_item_id, i.i_brand_id, i.i_units
)
SELECT
    isales.i_item_id,
    isales.i_brand_id,
    isales.i_units,
    isales.store_net_paid,
    isales.web_net_paid,
    isales.total_net_paid,
    cd_store.cd_gender,
    cd_store.cd_marital_status,
    cd_bill.cd_credit_rating,
    RANK() OVER (PARTITION BY isales.i_brand_id ORDER BY isales.total_net_paid DESC) AS brand_rank,
    CASE
        WHEN isales.total_net_paid > (SELECT AVG(total_net_paid) FROM item_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_category
FROM item_sales isales
JOIN store_sales ss ON ss.ss_item_sk = isales.i_item_sk
JOIN customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
JOIN web_sales ws ON ws.ws_item_sk = isales.i_item_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
WHERE cd_store.cd_gender = 'M'
  AND cd_store.cd_marital_status = 'M'
  AND cd_bill.cd_credit_rating = 'A'
  AND isales.i_brand_id = 6008007
  AND isales.i_units = 'Box'
ORDER BY isales.total_net_paid DESC
LIMIT 100
