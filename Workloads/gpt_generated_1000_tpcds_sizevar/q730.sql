WITH base AS (
  SELECT
    cr.cr_order_number                AS cr_order_number,
    cr.cr_return_amount               AS cr_return_amount,
    cr.cr_return_quantity             AS cr_return_quantity,
    cr.cr_returned_date_sk            AS cr_returned_date_sk,
    c.c_customer_sk                   AS c_customer_sk,
    c.c_birth_month                   AS c_birth_month,
    i.i_item_sk                       AS i_item_sk,
    i.i_category                      AS i_category,
    i.i_brand                         AS i_brand,
    p.p_promo_id                      AS p_promo_id,
    w.w_warehouse_sk                  AS w_warehouse_sk,
    s.s_store_sk                      AS s_store_sk,
    s.s_state                         AS s_state,
    r.r_reason_id                     AS r_reason_id,
    sr.sr_return_amt                  AS sr_return_amt,
    sr.sr_return_quantity             AS sr_return_quantity,
    wr.wr_return_amt                  AS wr_return_amt,
    wr.wr_return_quantity             AS wr_return_quantity,
    -- total amount returned across all channels for this line
    (cr.cr_return_amount + sr.sr_return_amt + wr.wr_return_amt) AS total_return_amount
  FROM catalog_returns cr
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
  WHERE c.c_birth_month IN (1, 4, 7, 9)
    AND i.i_brand = 'Brand#23'
    AND p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2451000
),
agg AS (
  SELECT
    c_customer_sk,
    s_state,
    i_category,
    SUM(total_return_amount) AS sum_return_amount,
    COUNT(*)               AS cnt_returns
  FROM base
  GROUP BY CUBE (c_customer_sk, s_state, i_category)
  HAVING SUM(total_return_amount) > 1000
),
ranked AS (
  SELECT
    c_customer_sk,
    s_state,
    i_category,
    sum_return_amount,
    cnt_returns,
    ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY sum_return_amount DESC) AS rn,
    (SELECT COUNT(*) FROM reason) AS total_reason_cnt
  FROM agg
)
SELECT
  r.c_customer_sk,
  r.s_state,
  r.i_category,
  r.sum_return_amount,
  r.cnt_returns,
  r.rn,
  r.total_reason_cnt
FROM ranked r
WHERE r.c_customer_sk NOT IN (
        SELECT sr_customer_sk FROM store_returns WHERE sr_return_quantity > 10
      )
  AND r.c_customer_sk NOT IN (
        SELECT cr_order_number FROM catalog_returns
        EXCEPT
        SELECT wr_order_number FROM web_returns
      )
ORDER BY r.sum_return_amount DESC
LIMIT 100
