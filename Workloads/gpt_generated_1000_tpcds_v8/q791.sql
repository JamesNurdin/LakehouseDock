WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        d.d_year,
        t.t_hour,
        i.i_manufact,
        i.i_class,
        i.i_item_id,
        regexp_extract(i.i_manufact, '(\\w+)')               AS manufact_word,
        CASE WHEN i.i_class LIKE '%shirts%' THEN 'Shirts' ELSE 'Other' END AS class_category,
        ROW_NUMBER() OVER (PARTITION BY i.i_manufact ORDER BY cr.cr_return_amount DESC) AS rn_by_manufact,
        ROW_NUMBER() OVER (ORDER BY cr.cr_return_amount DESC)                         AS global_rn,
        (
            SELECT sum(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_refunded_customer_sk = cr.cr_refunded_customer_sk
        )                                                                              AS customer_total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d   ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t   ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i       ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c   ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_manufact, '^e')
      AND i.i_class LIKE '%shirts%'
),
anti_keys AS (
    SELECT DISTINCT cr_returning_customer_sk AS returning_sk
    FROM catalog_returns
    WHERE cr_return_amount > 5000
)
SELECT
    fr.cr_returned_date_sk,
    fr.cr_returned_time_sk,
    fr.cr_item_sk,
    fr.cr_refunded_customer_sk,
    fr.cr_return_amount,
    fr.cr_net_loss,
    fr.d_year,
    fr.t_hour,
    fr.i_manufact,
    fr.i_class,
    fr.manufact_word,
    fr.class_category,
    fr.rn_by_manufact,
    fr.global_rn,
    fr.customer_total_return_amount
FROM filtered_returns fr
WHERE fr.cr_refunded_customer_sk NOT IN (SELECT returning_sk FROM anti_keys)
UNION
SELECT
    cr.cr_returned_date_sk,
    cr.cr_returned_time_sk,
    cr.cr_item_sk,
    cr.cr_refunded_customer_sk,
    cr.cr_return_amount,
    cr.cr_net_loss,
    d.d_year,
    t.t_hour,
    i.i_manufact,
    i.i_class,
    regexp_extract(i.i_manufact, '(\\w+)')               AS manufact_word,
    CASE WHEN i.i_class LIKE '%pants%' THEN 'Pants' ELSE 'Other' END AS class_category,
    ROW_NUMBER() OVER (PARTITION BY i.i_manufact ORDER BY cr.cr_return_amount DESC) AS rn_by_manufact,
    ROW_NUMBER() OVER (ORDER BY cr.cr_return_amount DESC)                         AS global_rn,
    (
        SELECT sum(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = cr.cr_refunded_customer_sk
    )                                                                              AS customer_total_return_amount
FROM catalog_returns cr
JOIN date_dim d   ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t   ON cr.cr_returned_time_sk = t.t_time_sk
JOIN item i       ON cr.cr_item_sk = i.i_item_sk
JOIN customer c   ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE d.d_year = 2001
  AND i.i_manufact LIKE '%stable%'
  AND i.i_class LIKE '%pants%'
  AND cr.cr_refunded_customer_sk NOT IN (SELECT returning_sk FROM anti_keys)
ORDER BY cr_return_amount DESC
LIMIT 100
