WITH filtered_customers AS (
    SELECT c_customer_sk, c_salutation, c_last_review_date, c_current_cdemo_sk
    FROM customer
    WHERE c_salutation = 'Ms.'
      AND c_last_review_date = 2452398
)
SELECT
    r.r_reason_desc,
    cd.cd_gender,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    AVG(ss.ss_wholesale_cost) AS avg_wholesale_cost,
    CASE
        WHEN SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) > 10000 THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category
FROM catalog_returns cr
JOIN filtered_customers c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN store_sales ss
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
WHERE ss.ss_wholesale_cost > 30
  AND ss.ss_coupon_amt < 5000
  AND r.r_reason_id = 'AAAAAAAABBAAAAAA'
  AND cd.cd_gender = 'M'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_returned_date_sk = cr.cr_returned_date_sk
          AND cr3.cr_return_amount > 100
    )
GROUP BY r.r_reason_desc, cd.cd_gender
ORDER BY total_store_net_loss DESC
LIMIT 100
