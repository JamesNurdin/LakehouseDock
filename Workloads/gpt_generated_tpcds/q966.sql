WITH returns_agg AS (
    SELECT
        sr.sr_ticket_number AS ticket_number,
        sum(sr.sr_net_loss) AS total_return_loss,
        count(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    WHERE dr.d_date >= DATE '2023-01-01'
      AND dr.d_date < DATE '2024-01-01'
    GROUP BY sr.sr_ticket_number
)
SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    sum(ss.ss_net_profit) AS total_net_profit,
    coalesce(sum(r.total_return_loss), 0) AS total_return_loss,
    sum(ss.ss_net_profit) - coalesce(sum(r.total_return_loss), 0) AS net_profit_after_returns,
    count(distinct ss.ss_ticket_number) AS sales_transactions,
    coalesce(sum(r.return_cnt), 0) AS return_transactions
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN returns_agg r
    ON ss.ss_ticket_number = r.ticket_number
WHERE d.d_date >= DATE '2023-01-01'
  AND d.d_date < DATE '2024-01-01'
GROUP BY s.s_store_name, d.d_year, d.d_month_seq, i.i_category
ORDER BY s.s_store_name, d.d_year, d.d_month_seq, i.i_category
