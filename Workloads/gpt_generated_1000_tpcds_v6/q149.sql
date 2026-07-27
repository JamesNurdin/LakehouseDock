WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cs.cs_order_number,
        cr.cr_returned_date_sk,
        wr.wr_returned_date_sk,
        sr.sr_returned_date_sk,
        d.d_year,
        i.i_brand,
        i.i_category,
        r.r_reason_desc,
        t.t_shift,
        sr.sr_reason_sk,
        cr.cr_reason_sk,
        wr.wr_reason_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                               AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = ss.ss_item_sk
                               AND cs.cs_sold_date_sk = ss.ss_sold_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = ss.ss_item_sk
                                 AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN web_returns wr ON wr.wr_item_sk = ss.ss_item_sk
                               AND wr.wr_returned_date_sk = ss.ss_sold_date_sk
    LEFT JOIN reason r ON r.r_reason_sk = COALESCE(sr.sr_reason_sk, cr.cr_reason_sk, wr.wr_reason_sk)
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND t.t_shift = 'second'
      AND i.i_brand = 'Brand#12'
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc <> 'Wrong size')
      AND ss.ss_net_profit > 0
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    SUM(base.ss_net_paid) AS total_net_paid,
    SUM(base.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT base.ss_ticket_number) AS distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(base.ss_net_profit) DESC) AS profit_rank,
    COALESCE(base.r_reason_desc, 'No Return') AS return_reason
FROM base
JOIN date_dim d ON base.ss_sold_date_sk = d.d_date_sk
JOIN item i ON base.ss_item_sk = i.i_item_sk
GROUP BY
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    base.r_reason_desc
ORDER BY total_net_profit DESC, d.d_date
LIMIT 100
