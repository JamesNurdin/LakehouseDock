WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        ss_ticket_number,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discount,
        SUM(ss_net_paid) AS net_paid,
        SUM(ss_net_profit) AS net_profit
    FROM store_sales
    GROUP BY ss_store_sk, ss_item_sk, ss_ticket_number
),
returns_agg AS (
    SELECT
        sr_store_sk,
        sr_item_sk,
        sr_ticket_number,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_refunded_cash) AS total_refunded_cash,
        SUM(sr_net_loss) AS total_net_loss
    FROM store_returns
    GROUP BY sr_store_sk, sr_item_sk, sr_ticket_number
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    COALESCE(sa.total_quantity, 0) AS total_sold_quantity,
    COALESCE(sa.total_sales, 0) AS total_sales_amount,
    COALESCE(ra.total_return_qty, 0) AS total_return_quantity,
    COALESCE(ra.total_return_amt, 0) AS total_return_amount,
    (COALESCE(sa.total_sales, 0) - COALESCE(ra.total_return_amt, 0)) AS net_sales_after_returns,
    (COALESCE(sa.net_profit, 0) - COALESCE(ra.total_net_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (COALESCE(sa.total_sales, 0) - COALESCE(ra.total_return_amt, 0)) DESC) AS sales_rank
FROM store s
LEFT JOIN sales_agg sa
    ON sa.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg ra
    ON ra.sr_store_sk = s.s_store_sk
    AND ra.sr_item_sk = sa.ss_item_sk
    AND ra.sr_ticket_number = sa.ss_ticket_number
ORDER BY net_sales_after_returns DESC
LIMIT 100
