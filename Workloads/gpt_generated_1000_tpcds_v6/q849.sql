WITH sales_by_demo AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        AVG(ss.ss_ext_sales_price) AS store_sales_avg,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        AVG(ws.ws_ext_sales_price) AS web_sales_avg
    FROM customer_demographics cd
    JOIN store_sales ss
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_education_status = '4 yr Degree'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ss.ss_quantity > 1
      AND ws.ws_ext_ship_cost > 500
      AND ss.ss_ext_discount_amt < 200
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_education_status
)
SELECT
    sbd.cd_demo_sk,
    sbd.cd_gender,
    sbd.cd_education_status,
    sbd.store_txn_cnt,
    sbd.store_sales_total,
    sbd.store_sales_avg,
    sbd.web_txn_cnt,
    sbd.web_sales_total,
    sbd.web_sales_avg,
    COUNT(cr.cr_order_number) AS return_order_cnt,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    (SELECT MIN(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_refunded_cdemo_sk = sbd.cd_demo_sk) AS min_return_amount
FROM sales_by_demo sbd
JOIN catalog_returns cr
    ON cr.cr_refunded_cdemo_sk = sbd.cd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr_ex
    WHERE cr_ex.cr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND cr_ex.cr_refunded_cdemo_sk = sbd.cd_demo_sk
      AND cr_ex.cr_return_quantity > 0
)
GROUP BY sbd.cd_demo_sk,
         sbd.cd_gender,
         sbd.cd_education_status,
         sbd.store_txn_cnt,
         sbd.store_sales_total,
         sbd.store_sales_avg,
         sbd.web_txn_cnt,
         sbd.web_sales_total,
         sbd.web_sales_avg,
         (SELECT MIN(cr2.cr_return_amount)
          FROM catalog_returns cr2
          WHERE cr2.cr_refunded_cdemo_sk = sbd.cd_demo_sk)
ORDER BY total_return_net_loss DESC
LIMIT 100
