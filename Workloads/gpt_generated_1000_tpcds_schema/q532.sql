WITH sampled_sales AS (
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_customer_sk,
           ss_cdemo_sk,
           ss_promo_sk,
           ss_ticket_number,
           ss_ext_discount_amt,
           ss_ext_tax,
           ss_net_paid_inc_tax,
           ss_quantity
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined_all AS (
    SELECT cr.cr_returned_date_sk,
           cr.cr_item_sk,
           cr.cr_return_amount,
           cd.cd_gender,
           cd.cd_education_status,
           i.i_size,
           i.i_category,
           p.p_channel_radio,
           sr.sr_return_amt,
           sr.sr_fee,
           ss.ss_ext_discount_amt,
           ss.ss_ext_tax,
           ss.ss_net_paid_inc_tax
    FROM catalog_returns cr
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN sampled_sales ss
      ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
      ON p.p_item_sk = i.i_item_sk
     AND p.p_promo_sk = ss.ss_promo_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE i.i_size IN ('small', 'medium')
      AND cd.cd_education_status = 'College'
      AND p.p_channel_radio = 'N'
      AND ss.ss_ext_discount_amt > 20
      AND ss.ss_ext_tax < 150
),
union_agg AS (
    SELECT cr_returned_date_sk,
           cr_item_sk,
           cd_gender,
           i_category,
           SUM(cr_return_amount) AS total_return_amount,
           COUNT(*) AS cnt_returns,
           CASE WHEN SUM(cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS return_level
    FROM joined_all
    GROUP BY cr_returned_date_sk, cr_item_sk, cd_gender, i_category
    HAVING COUNT(*) > 1
    UNION
    SELECT cr_returned_date_sk,
           cr_item_sk,
           cd_gender,
           i_category,
           SUM(cr_return_amount) AS total_return_amount,
           COUNT(*) AS cnt_returns,
           CASE WHEN SUM(cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS return_level
    FROM joined_all
    WHERE cr_return_amount IS NOT NULL
    GROUP BY cr_returned_date_sk, cr_item_sk, cd_gender, i_category
)
SELECT *
FROM union_agg
EXCEPT
SELECT cr_returned_date_sk,
       cr_item_sk,
       cd_gender,
       i_category,
       total_return_amount,
       cnt_returns,
       return_level
FROM union_agg
WHERE return_level = 'Low'
ORDER BY total_return_amount DESC
LIMIT 100
