WITH catalog_items AS (
    SELECT cr.cr_item_sk AS item_sk,
           i.i_item_id,
           SUM(cr.cr_return_amount) AS total_catalog_return_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 100.00
    GROUP BY cr.cr_item_sk, i.i_item_id
),
web_items AS (
    SELECT wr.wr_item_sk AS item_sk,
           i.i_item_id,
           SUM(wr.wr_return_amt) AS total_web_return_amount
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt > 50.00
    GROUP BY wr.wr_item_sk, i.i_item_id
),
intersect_items AS (
    SELECT ci.item_sk, ci.i_item_id
    FROM catalog_items ci
    INTERSECT
    SELECT wi.item_sk, wi.i_item_id
    FROM web_items wi
),
except_items AS (
    SELECT ii.item_sk, ii.i_item_id
    FROM intersect_items ii
    EXCEPT
    SELECT cr.cr_item_sk, i.i_item_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_refunded_customer_sk = 11253159
)
SELECT ei.item_sk,
       ei.i_item_id,
       (
           SELECT SUM(cr2.cr_return_amount)
           FROM catalog_returns cr2
           WHERE cr2.cr_item_sk = ei.item_sk
       ) AS catalog_return_sum,
       (
           SELECT SUM(wr2.wr_return_amt)
           FROM web_returns wr2
           WHERE wr2.wr_item_sk = ei.item_sk
       ) AS web_return_sum
FROM except_items ei
ORDER BY ei.item_sk
