WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
hour_dim AS (
    SELECT DISTINCT t_hour
    FROM time_dim
    WHERE t_hour IN (0, 12)
),
item_intersect AS (
    SELECT i_item_sk
    FROM item
    WHERE i_brand = 'BrandX'
),
promo_intersect AS (
    SELECT p_item_sk AS i_item_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
)
SELECT DISTINCT
    c1.c_customer_id,
    i1.i_item_id,
    i1.i_item_desc,
    sr.sr_return_amt,
    SUM(sr.sr_return_amt) OVER (
        PARTITION BY c1.c_customer_sk
        ORDER BY sr.sr_return_time_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_return_amt,
    inv_agg.total_quantity_on_hand,
    p.p_promo_name,
    COALESCE(wr.wr_return_amt, 0) AS web_return_amt,
    t1.t_hour,
    h.t_hour AS cross_hour
FROM store_returns sr
JOIN time_dim t1
    ON sr.sr_return_time_sk = t1.t_time_sk
JOIN item i1
    ON sr.sr_item_sk = i1.i_item_sk
JOIN customer c1
    ON sr.sr_customer_sk = c1.c_customer_sk
LEFT JOIN promotion p
    ON p.p_item_sk = i1.i_item_sk
JOIN inv_agg
    ON inv_agg.inv_item_sk = i1.i_item_sk
FULL OUTER JOIN web_returns wr
    ON wr.wr_item_sk = i1.i_item_sk
LEFT JOIN time_dim t2
    ON wr.wr_returned_time_sk = t2.t_time_sk
LEFT JOIN customer c2
    ON wr.wr_refunded_customer_sk = c2.c_customer_sk
CROSS JOIN hour_dim h
WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i1.i_item_sk
          AND wr2.wr_returned_date_sk = sr.sr_returned_date_sk
      )
  AND i1.i_item_sk IN (
        SELECT i_item_sk FROM item_intersect
        INTERSECT
        SELECT i_item_sk FROM promo_intersect
      )
  AND (
        SELECT COUNT(*)
        FROM store_returns sr_sub
        WHERE sr_sub.sr_customer_sk = c1.c_customer_sk
          AND sr_sub.sr_return_amt > 100
      ) > 0
ORDER BY running_return_amt DESC
LIMIT 100
