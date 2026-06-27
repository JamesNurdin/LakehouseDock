-- Net profit per store by month for the year 2001, accounting for returns
WITH sales_with_returns AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_moy,
        ss.ss_net_profit,
        ss.ss_quantity,
        sr.sr_net_loss,
        sr.sr_return_quantity
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
        AND dr.d_date >= DATE '2001-01-01'
        AND dr.d_date < DATE '2002-01-01'
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
)
SELECT
    s_store_id,
    d_year,
    d_moy,
    sum(ss_net_profit) AS total_sales_profit,
    sum(sr_net_loss) AS total_return_loss,
    sum(ss_quantity) AS total_quantity_sold,
    sum(sr_return_quantity) AS total_quantity_returned,
    sum(ss_net_profit) - sum(sr_net_loss) AS net_profit_after_returns
FROM sales_with_returns
GROUP BY s_store_id, d_year, d_moy
ORDER BY net_profit_after_returns DESC
LIMIT 100
