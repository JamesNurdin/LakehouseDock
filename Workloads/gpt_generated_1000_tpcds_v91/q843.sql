WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_customer_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_returning_addr_sk,
        cr.cr_reason_sk,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
      AND d.d_moy = 5
      AND cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 1
)
SELECT
    ca.ca_city,
    t.word AS reason_word,
    cd.cd_gender,
    COUNT(*) AS return_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_net_loss) AS avg_net_loss,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount
FROM filtered_returns fr
JOIN customer c
    ON fr.cr_returning_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON fr.cr_returning_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON fr.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON fr.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
CROSS JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
WHERE cd.cd_marital_status = 'M'
  AND cd.cd_education_status = '4 yr Degree'
  AND ca.ca_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = fr.cr_reason_sk
          AND r2.r_reason_desc LIKE '%Damaged%'
    )
  AND NOT EXISTS (
        SELECT 1
        FROM customer_address ca_ref
        WHERE ca_ref.ca_address_sk = fr.cr_refunded_addr_sk
          AND ca_ref.ca_city = 'Edgewood'
    )
GROUP BY ca.ca_city, t.word, cd.cd_gender
ORDER BY total_return_amount DESC, return_cnt DESC
LIMIT 100
