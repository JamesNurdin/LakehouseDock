WITH customer_page_stats AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT wp.wp_web_page_sk) AS page_count,
           SUM(wp.wp_max_ad_count) AS total_ad_capacity
    FROM customer c
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT i.i_category,
       cd.cd_gender,
       cd.cd_marital_status,
       COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
       SUM(sr.sr_return_amt) AS total_return_amount,
       SUM(sr.sr_net_loss) AS total_net_loss,
       AVG(sr.sr_return_amt) AS avg_return_amount,
       COUNT(DISTINCT r.r_reason_id) AS distinct_return_reasons,
       AVG(cp.page_count) AS avg_pages_per_customer,
       RANK() OVER (ORDER BY SUM(sr.sr_return_amt) DESC) AS category_rank
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_page_stats cp ON sr.sr_customer_sk = cp.c_customer_sk
WHERE sr.sr_returned_date_sk BETWEEN 20200101 AND 20201231
  AND i.i_category <> ''
GROUP BY i.i_category, cd.cd_gender, cd.cd_marital_status
HAVING SUM(sr.sr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 50
