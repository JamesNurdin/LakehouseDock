/*
  Net sales and profit analysis per store and month (1998).
  The query aggregates sales, discounts, returns, and profit,
  and also counts distinct promotions used.
*/
WITH returns_agg AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_store_sk,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_net_loss)      AS total_net_loss
    FROM store_returns sr
    GROUP BY
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_store_sk
)
SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_paid)                         AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt)                 AS total_discount_amount,
    SUM(COALESCE(r.total_refunded_cash, 0))      AS total_refunded_cash,
    SUM(ss.ss_net_profit)                       AS total_profit_before_returns,
    SUM(COALESCE(r.total_net_loss, 0))           AS total_loss_from_returns,
    (SUM(ss.ss_net_paid) - SUM(COALESCE(r.total_refunded_cash, 0))) AS net_sales_amount,
    (SUM(ss.ss_net_profit) - SUM(COALESCE(r.total_net_loss, 0)))      AS net_profit_amount,
    COUNT(DISTINCT ss.ss_promo_sk)               AS distinct_promotions_used
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg r
  ON ss.ss_ticket_number = r.sr_ticket_number
 AND ss.ss_item_sk       = r.sr_item_sk
 AND s.s_store_sk        = r.sr_store_sk
WHERE d.d_date >= DATE '1998-01-01'
  AND d.d_date <  DATE '1999-01-01'
GROUP BY
    s.s_store_name,
    d.d_year,
    d.d_month_seq
ORDER BY
    s.s_store_name,
    d.d_year,
    d.d_month_seq
