WITH sales_with_date AS (
    SELECT
        ss.ss_sold_date_sk AS d_date_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_net_profit,
        ss.ss_ext_list_price,
        ss.ss_quantity,
        d.d_year,
        d.d_qoy,
        d.d_month_seq
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
      AND ss.ss_ext_list_price > 1000
),
returns AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
),
catalog_ret AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_store_credit
    FROM catalog_returns cr
    WHERE cr.cr_fee > 10
),
inventory_filtered AS (
    SELECT
        i.inv_date_sk,
        i.inv_item_sk,
        i.inv_quantity_on_hand
    FROM inventory i
    WHERE i.inv_quantity_on_hand > 0
)
SELECT
    s.d_year,
    s.d_qoy,
    s.ss_store_sk,
    s.ss_item_sk,
    s.ss_ext_list_price,
    s.ss_net_profit,
    r.sr_return_quantity,
    cr.cr_return_amount,
    i.inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY s.ss_store_sk ORDER BY s.ss_net_profit DESC) AS profit_rank,
    CASE
        WHEN r.sr_return_quantity IS NULL THEN 'No Return'
        WHEN r.sr_return_quantity > 5 THEN 'High Return'
        ELSE 'Low Return'
    END AS return_category,
    (
        SELECT AVG(ss_inner.ss_net_profit)
        FROM store_sales ss_inner
        WHERE ss_inner.ss_sold_date_sk = s.d_date_sk
    ) AS avg_profit_same_date
FROM sales_with_date s
JOIN returns r
    ON r.sr_item_sk = s.ss_item_sk
   AND r.sr_ticket_number = s.ss_ticket_number
JOIN catalog_ret cr
    ON cr.cr_returned_date_sk = s.d_date_sk
JOIN inventory_filtered i
    ON i.inv_date_sk = s.d_date_sk
   AND i.inv_item_sk = s.ss_item_sk
WHERE i.inv_quantity_on_hand > 10
ORDER BY s.ss_net_profit DESC
LIMIT 100
